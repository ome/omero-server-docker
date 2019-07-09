FROM centos:centos7
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"
LABEL org.opencontainers.image.created="2019-07-09T09:45:51Z"
LABEL org.opencontainers.image.revision="dc73b8def025ba83708df72a3dd1235201a36f5b"
LABEL org.opencontainers.image.source="https://github.com/openmicroscopy/omero-server-docker"

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN yum -y install epel-release \
    && yum -y install ansible sudo \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=5.5.1
ARG OMEGO_ADDITIONAL_ARGS=
RUN ansible-playbook playbook.yml \
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 && \
    chmod +x /usr/local/bin/dumb-init
ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server

# Fixed in 5.5.0 https://github.com/openmicroscopy/openmicroscopy/pull/5949
RUN sed -i.bak -re \
    's/(name="omero.fs.importArgs"\s+value=)""/\1"--no-upgrade-check"/' \
    /opt/omero/server/OMERO.server/etc/templates/grid/templates.xml
EXPOSE 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
