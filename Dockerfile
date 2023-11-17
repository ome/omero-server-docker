FROM ubuntu:22.04
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"

ENV LANG en_US.utf-8
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN apt update\
    && apt install -y ansible sudo ca-certificates dumb-init \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml \
    && apt -y autoclean autoremove \
    && rm -fr /var/lib/apt/lists/* /tmp/*

ARG OMERO_VERSION=5.6.9
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server/

RUN ansible-playbook playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS" \
    && apt -y autoclean autoremove \
    && rm -fr /var/lib/apt/lists/* /tmp/*

ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server
EXPOSE 4063 4064
ENV PATH=$PATH:/opt/ice/bin

VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
