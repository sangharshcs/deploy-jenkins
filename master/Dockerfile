FROM jenkinsci/blueocean
 
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djava.util.logging.config.file=/var/jenkins_home/log.properties"
ENV JENKINS_OPTS="--prefix=/jenkins" 
 
COPY security.groovy /usr/share/jenkins/ref/init.groovy.d/security.groovy
 
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt
