FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

ARG OMERO_VERSION=latest
ARG CI_SERVER
ARG OMEGO_ARGS

WORKDIR /home/omero

ADD omero-grid-deps.yml requirements.yml slave.cfg run.sh process_defaultxml.py /home/omero/

RUN yum -y install epel-release \
    && yum -y install ansible \
    && ansible-galaxy install -r requirements.yml \
    && ansible-playbook omero-grid-deps.yml \
    && pip install omego \
    && useradd omero \
    && chown omero:omero -R . \
    # https://github.com/docker/docker/issues/2259#issuecomment-48286811
    && mkdir /OMERO \
    # Ensure /OMERO is owned by the omero user
    && chown omero:omero -R /OMERO

USER omero

RUN bash -c 'CI=; if [ -n "$CI_SERVER" ]; then CI="--ci $CI_SERVER"; fi; \
             omego download server $CI --release $OMERO_VERSION $OMEGO_ARGS' \
    && rm OMERO.server-*.zip \
    && ln -s OMERO.server-*/ OMERO.server \
    # default.xml may be modified at runtime for a multinode configuration
    && cp OMERO.server/etc/templates/grid/default.xml OMERO.server/etc/templates/grid/default.xml.orig

EXPOSE 4061 4063 4064
VOLUME ["/OMERO", "/home/omero/OMERO.server/var"]
ENTRYPOINT ["/home/omero/run.sh"]
