SHELL := /bin/bash
CURR_DIR = $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

ifndef JENKINS_SERVER_IP
$(error JENKINS_SERVER_IP is not set, export JENKINS_SERVER_IP=<public ip of server>)
endif

VERSION := $(shell cat ${CURR_DIR}/VERSION)
MASTER_IMAGE := sangharshcs/jenkins-master:$(VERSION)
SLAVE_IMAGE := sangharshcs/jenkins-slave:$(VERSION)
MASTER_ROOT := /opt/jenkins_home
SLAVE_ROOT := /opt/slave_home
MASTER_SERVICE := "jenkins-master"
SLAVE_SERVICE := "jenkins-slave"
JENKINS_USER := admin
JENKINS_PASS := admin
JENKINS_HOST_PORT := ${JENKINS_SERVER_IP}:8080
JENKINS_ACCESS_URL := http://${JENKINS_USER}:${JENKINS_PASS}@${JENKINS_HOST_PORT}
