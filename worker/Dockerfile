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
    rm -rf /var/lib/apt/lists/* && \
    groupadd -g 10001 jenkins && \
    useradd -u 10001 -g jenkins -m -d /home/jenkins jenkins && \
    mkdir -p /opt/worker_home && \
    chown jenkins:jenkins /opt/worker_home

# Docker socket access is opt-in; see README §Security before enabling it.
COPY --chown=jenkins:jenkins --chmod=750 start.sh /start.sh

USER jenkins

CMD ["/start.sh"]
