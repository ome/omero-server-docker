FROM centos:centos7
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

RUN yum -y install epel-release && \
    curl -o /etc/yum.repos.d/zeroc-ice-el7.repo \
        http://download.zeroc.com/Ice/3.5/el7/zeroc-ice-el7.repo && \
    yum -y install \
        unzip wget patch \
        java-1.8.0-openjdk \
        ice ice-python ice-servers \
        python-pip \
        numpy scipy python-matplotlib python-pillow python-tables \
        postgresql && \
    yum clean all

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

# TODO: `Ice.Default.Host` breaks a multinode configuration, replace with
# a different property name in templates and in `admin rewrite`
RUN sed -i s/Ice\.Default\.Host/omero.master.host/g \
    OMERO.server/lib/python/omero/plugins/admin.py \
    OMERO.server/etc/templates/*.cfg OMERO.server/etc/templates/*.config \
    OMERO.server/etc/templates/grid/*.xml

# default.xml may be modified at runtime for a multinode configuration
RUN cp OMERO.server/etc/templates/grid/default.xml \
    OMERO.server/etc/templates/grid/default.xml.orig

ADD slave.cfg /home/omero/OMERO.server/etc/templates/
ADD run.sh process_defaultxml.py /home/omero/

EXPOSE 4061 4063 4064

VOLUME ["/OMERO", "/home/omero/OMERO.server/var"]

# Set the default command to run when starting the container
ENTRYPOINT ["/home/omero/run.sh"]
