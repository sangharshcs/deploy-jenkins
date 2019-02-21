#!/bin/bash

wget https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/3.9/swarm-client-3.9.jar --directory-prefix=/home/jenkins

java -jar /home/jenkins/swarm-client-3.9.jar -master ${J_MASTER} -username ${J_USERNAME} -password ${J_PASSWORD} -fsroot ${SLAVE_ROOT} -executors 5 -labels "swarm docker" -candidateTag "jenkins-slave"
