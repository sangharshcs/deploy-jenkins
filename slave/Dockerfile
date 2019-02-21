FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y python lsb-core docker.io
RUN apt-get install -y sudo

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

ENV HOME /home/${user}
RUN groupadd -g ${gid} ${group}
RUN groupmod -g 117 docker
RUN useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -G docker,sudo -m ${user}
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

USER ${user}
WORKDIR /home/${user}

COPY start.sh ${HOME}/
RUN ls -l ${HOME}/
RUN sudo chmod 777 ${HOME}/start.sh

CMD ${HOME}/start.sh
