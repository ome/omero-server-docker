FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk


RUN yum -y install epel-release && \
    yum -y install ansible

RUN mkdir /opt/infrastructure
ADD omero-grid-deps.yml requirements.yml /opt/infrastructure/

RUN cd /opt/infrastructure && \
    ansible-galaxy install -r requirements.yml && \
    ansible-playbook omero-grid-deps.yml

RUN pip install omego

RUN useradd omero && \
    mkdir /OMERO && \
    chown omero /OMERO

ARG OMERO_VERSION=latest
ARG CI_SERVER
ARG OMEGO_ARGS

USER omero
WORKDIR /home/omero
RUN bash -c 'CI=; if [ -n "$CI_SERVER" ]; then CI="--ci $CI_SERVER"; fi; \
    omego download server $CI --release $OMERO_VERSION $OMEGO_ARGS && \
        rm OMERO.server-*.zip && \
        ln -s OMERO.server-*/ OMERO.server'

# default.xml may be modified at runtime for a multinode configuration
RUN cp OMERO.server/etc/templates/grid/default.xml \
    OMERO.server/etc/templates/grid/default.xml.orig

ADD slave.cfg /home/omero/OMERO.server/etc/templates/
ADD run.sh process_defaultxml.py /home/omero/

EXPOSE 4061 4063 4064

VOLUME ["/OMERO", "/home/omero/OMERO.server/var"]

# Set the default command to run when starting the container
ENTRYPOINT ["/home/omero/run.sh"]
