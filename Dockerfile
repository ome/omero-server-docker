FROM rockylinux:9.3
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"

RUN dnf -y install epel-release
RUN dnf -y update
RUN dnf install -y glibc-langpack-en

ENV LANG en_US.utf-8
ENV RHEL_FRONTEND=noninteractive
RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN dnf install -y ansible-core sudo ca-certificates
RUN ansible-galaxy install -p /opt/setup/roles -r requirements.yml


RUN dnf -y clean all
RUN rm -fr /var/cache

ARG OMERO_VERSION=5.6.10
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server

RUN ansible-playbook playbook.yml -vvv -e 'ansible_python_interpreter=/usr/bin/python3'\
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN dnf -y clean all
RUN rm -fr /var/cache

WORKDIR /opt

RUN source  omero/server/venv3/bin/activate

RUN dnf install -y dumb-init

ADD entrypoint.sh /usr/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/


USER omero-server
EXPOSE 4063 4064
ENV PATH=$PATH:/opt/ice/bin

VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]


ENTRYPOINT ["/usr/bin/entrypoint.sh"]
