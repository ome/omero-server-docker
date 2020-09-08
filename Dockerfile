FROM centos:centos7
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="2020-09-08T13:02:55Z"
LABEL org.opencontainers.image.revision="d2393891ab0dfa64bd128724d9f4bfc3523f47e2"
LABEL org.opencontainers.image.source="https://github.com/openmicroscopy/omero-server-docker"

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN yum -y install epel-release \
    && yum -y install ansible sudo \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=5.6.2
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server/
RUN ansible-playbook playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server
EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
