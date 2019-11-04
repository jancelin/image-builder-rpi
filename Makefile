


BEFORE: 

 cd geo-poppy
 docker-compose pull
 docker save -o docker-images.tar $(docker-compose config | awk '{if ($1 == "image:") print $2;}' ORS=" ")
 chmod 655 docker-images.tar
 mv docker-images.tar /home/jancelin/image-builder-rpi/images/files/docker-images.tar

  docker run -p 8099:80 -d -v /home/jancelin/image-builder-rpi/images:/usr/local/apache2/htdocs httpd:2.4
  
  #and test
  http://172.17.0.1:8099/

build:
	docker build -t image-builder-rpi .

sd-image: build
	docker run --rm --privileged -v $(pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG=Centipede -e VERSION=V0.2.5 image-builder-rpi
	
	#univ
	
	docker run --rm --privileged -v $(pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -v /etc/resolv.conf:/etc/resolv.conf  -e CIRCLE_TAG=centipede -e VERSION=V0.2 image-builder-rpi

shell: build
	docker run -ti --privileged -v $(pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -v /etc/resolv.conf:/etc/resolv.conf -e CIRCLE_TAG=centipede -e VERSION=V0.2 image-builder-rpi bash
	

test:
	VERSION=dirty docker run --rm -ti --privileged -v $(shell pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG -e VERSION image-builder-rpi bash -c "unzip /workspace/hypriotos-rpi-dirty.img.zip && rspec --format documentation --colodocker run --rm --privileged -v $(pwd):/workspace -v /boot:/boot -v /lib/modules:/lib/modules -e CIRCLE_TAG=Centipede -e VERSION=V0.2.3 image-builder-rpir /workspace/builder/test/*_spec.rb"

shellcheck: build
	VERSION=dirty docker run --rm -ti -v $(shell pwd):/workspace image-builder-rpi bash -c 'shellcheck /workspace/builder/*.sh /workspace/builder/files/var/lib/cloud/scr+ipts/per-once/*'

test-integration: test-integration-image test-integration-docker

test-integration-image:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-image"

test-integration-docker:
	docker run --rm -ti -v $(shell pwd)/builder/test-integration:/serverspec:ro -e BOARD uzyexe/serverspec:2.24.3 bash -c "rspec --format documentation --color spec/hypriotos-docker"

tag:
	git tag ${TAG}
	git push origin ${TAG}
