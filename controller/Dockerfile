FROM jenkins/jenkins:lts-slim-jdk21

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djava.util.logging.config.file=/var/jenkins_home/log.properties" \
    JENKINS_OPTS="--prefix=/jenkins" \
    JENKINS_UC=https://updates.jenkins.io \
    JENKINS_UC_DOWNLOAD=https://updates.jenkins.io/download \
    JENKINS_PLUGIN_INFO=https://updates.jenkins.io/plugin-versions.json

COPY --chown=jenkins:jenkins security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
