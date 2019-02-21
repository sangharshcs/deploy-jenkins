SHELL := /bin/bash
current_dir = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include ${current_dir}/../env.mk

build:
	docker build -t ${SLAVE_IMAGE} .
push:
	docker push ${SLAVE_IMAGE}

wait:
	number=1 ; while [[ $$number -le 10 ]] ; do \
		curl ${JENKINS_ACCESS_URL}/jenkins/computer/api/json?pretty=true 2>/dev/null | grep -q '"totalExecutors" : 7'; \
		if [ $$? == 0 ];\
		then \
			echo "Jenkins slave is up and running"; \
			exit 0; \
		fi; \
		echo "Jenkins slave is still not up, waiting!!"; \
		sleep 12; \
		((number = number + 1)) ; \
	done;\
	echo "Jenkins slave is not up, exiting"; \
	exit 1; \

stop:
	if docker service ls| grep -q "${SLAVE_SERVICE}"; then \
		echo "jenkins slave is already present, removing it to launch new one"; \
		docker service rm ${SLAVE_SERVICE} || exit 1; \
		sleep 30; \
	fi;
	
prepare:
	if [ ! -d "${SLAVE_ROOT}" ]; then \
		echo "${SLAVE_ROOT} is not present, creating it."	; \
		mkdir -p -m 777 ${SLAVE_ROOT} || exit 1; \
	fi; \

create: stop prepare
	docker service create --name ${SLAVE_SERVICE} -e SLAVE_ROOT=${SLAVE_ROOT} -e J_USERNAME=${JENKINS_USER} -e J_PASSWORD=${JENKINS_PASS} -e J_MASTER="http://${JENKINS_HOST_PORT}/jenkins" --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" --mount "type=bind,source=${SLAVE_ROOT},target=${SLAVE_ROOT}" ${SLAVE_IMAGE} || exit 1; \
	sleep 30;

deploy:
	$(MAKE) create || exit 1; \
	$(MAKE) wait || exit 1; \
	echo "Jenkins slave is deployed, successfully!!";
