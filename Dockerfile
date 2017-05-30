FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN yum -y install epel-release \
    && yum -y install ansible sudo \
    && ansible-galaxy install -p /opt/setup/roles -r requirements.yml

ARG OMERO_VERSION=latest
RUN ansible-playbook playbook.yml -e omero_server_release=$OMERO_VERSION

RUN mkdir /startup
ADD slave.cfg process_defaultxml.py /opt/omero/server/
ADD run.sh /startup/
ADD run-exec.sh /

USER omero-server

# default.xml may be modified at runtime for a multinode configuration
RUN cp /opt/omero/server/OMERO.server/etc/templates/grid/default.xml /opt/omero/server/OMERO.server/etc/templates/grid/default.xml.orig

EXPOSE 4061 4063 4064
VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/run-exec.sh"]
