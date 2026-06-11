FROM ubuntu:24.04

ARG DOCKER_VERSION=29.5.3
ARG TARGETARCH=amd64

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64)   DOCKER_ARCH=x86_64   ;; \
      arm64)   DOCKER_ARCH=aarch64  ;; \
      *) echo "Unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      curl \
      wget \
      openjdk-21-jre-headless \
      ca-certificates && \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" \
      | tar -xz --strip-components=1 -C /usr/local/bin docker/docker && \
    rm -rf /var/lib/apt/lists/*

ARG user=jenkins

ENV HOME=/home/${user}

RUN useradd -c "Jenkins user" -d "$HOME" -m "${user}"
COPY --chown=${user}:${user} --chmod=750 start.sh ${HOME}/start.sh

USER ${user}
WORKDIR ${HOME}

CMD ["./start.sh"]
