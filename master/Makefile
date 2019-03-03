CURR_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include ${CURR_DIR}/../env.mk

build:
	docker build --no-cache -t ${MASTER_IMAGE} .

push:
	docker push ${MASTER_IMAGE}

create_yml:
	@sed \
		-e s#@MASTER_IMAGE@#$(MASTER_IMAGE)#g \
		-e s#@MASTER_ROOT@#$(MASTER_ROOT)#g \
	jenkins_master.yml >jenkins_master_copy.yml;
wait:
	number=1 ; while [[ $$number -le 10 ]] ; do \
		curl ${JENKINS_ACCESS_URL}/jenkins/api/json?pretty=true --write-out %{http_code} --silent --output /dev/null | grep -q 200; \
		if [ $$? == 0 ];\
		then \
			echo "Jenkins is up and running"; \
			exit 0; \
		fi; \
		echo "Jenkins Server is still not up, waiting!!"; \
		sleep 12; \
		((number = number + 1)) ; \
	done;\
	echo "Jenkins Server is not up, exiting"; \
	exit 1; \

stop:
	if docker stack ls| grep -q "${MASTER_SERVICE}"; then \
		echo "jenkins stack is already present, removing it to launch new one"; \
		docker stack rm ${MASTER_SERVICE} || exit 1; \
		sleep 30; \
	fi; \

prepare:
	if [ ! -d "${MASTER_ROOT}" ]; then \
		echo "${MASTER_ROOT} is not present, creating it."	; \
		mkdir -p -m 777 ${MASTER_ROOT} || exit 1; \
	fi; \
	if ! docker secret ls | grep -q "jenkins"; then \
		echo "docker secrets are not present, creating it"; \
		echo ${JENKINS_USER} | docker secret create jenkins-user - || exit 1; \
		echo ${JENKINS_PASS} | docker secret create jenkins-pass - || exit 1; \
	fi;\

create: create_yml stop prepare
	docker stack deploy -c jenkins_master_copy.yml ${MASTER_SERVICE} || exit 1;\
	sleep 30;

deploy:
	$(MAKE) create || exit 1; \
	$(MAKE) wait || exit 1; \
	echo "Jenkins master is deployed, successfully!!";
