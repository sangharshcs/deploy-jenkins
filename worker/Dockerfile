FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      lsb-release \
      docker.io \
      wget \
      openjdk-17-jre-headless \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG user=jenkins

ENV HOME=/home/${user}
RUN set -eux; \
    if ! id -u "${user}" >/dev/null 2>&1; then \
      useradd -c "Jenkins user" -d "$HOME" -G docker -m "${user}"; \
    fi

COPY start.sh ${HOME}/
RUN chown "${user}:${user}" ${HOME}/start.sh && chmod 750 ${HOME}/start.sh

USER ${user}
WORKDIR /home/${user}

CMD ["/home/jenkins/start.sh"]
