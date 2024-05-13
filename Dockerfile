FROM rockylinux:9
LABEL maintainer="ome-devel@lists.openmicroscopy.org.uk"

RUN dnf -y install epel-release
RUN dnf -y update
RUN dnf install -y glibc-langpack-en
RUN dnf install -y blosc

ENV LANG en_US.utf-8
ENV RHEL_FRONTEND=noninteractive
RUN mkdir /opt/setup
WORKDIR /opt/setup
ADD playbook.yml requirements.yml /opt/setup/

RUN dnf install -y ansible-core sudo ca-certificates
RUN ansible-galaxy install -p /opt/setup/roles -r requirements.yml
RUN dnf -y clean all
RUN rm -fr /var/cache

ARG OMERO_VERSION=5.6.11
ARG OMEGO_ADDITIONAL_ARGS=
ENV OMERODIR=/opt/omero/server/OMERO.server

RUN ansible-playbook playbook.yml -vvv -e 'ansible_python_interpreter=/usr/bin/python3'\
    -e omero_server_release=$OMERO_VERSION \
    -e omero_server_omego_additional_args="$OMEGO_ADDITIONAL_ARGS"

RUN dnf -y clean all
RUN rm -fr /var/cache

RUN curl -L -o /usr/local/bin/dumb-init \
    https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 && \
    chmod +x /usr/local/bin/dumb-init

ADD entrypoint.sh /usr/local/bin/
ADD 50-config.py 60-database.sh 99-run.sh /startup/

USER omero-server
EXPOSE 4063 4064
ENV PATH=$PATH:/opt/ice/bin

VOLUME ["/OMERO", "/opt/omero/server/OMERO.server/var"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
