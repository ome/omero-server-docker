ARG PARENT_IMAGE=openmicroscopy/omero-server-minimal:latest
FROM ${PARENT_IMAGE}

USER root
ADD wait-on-login import-all /tools/
ADD 95-background.sh /startup/
RUN mkdir /import && touch /import/test.fake
USER omero-server
