FROM eclipse-temurin:21-jre-ubi10-minimal

RUN microdnf install -y wget && \
    microdnf clean all

ARG user=jenkins

ENV HOME=/home/${user}
RUN useradd -c "Jenkins user" -d "$HOME" -m "${user}"

COPY --chown=${user}:${user} --chmod=750 start.sh ${HOME}/start.sh

USER ${user}
WORKDIR /home/${user}

CMD ["./start.sh"]
