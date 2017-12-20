#
# Usage:
#
#   make VERSION=x.y.z
#   git push origin x.y.z (or to snoopy for review)
#
# To trigger another build, use:
#
#   make VERSION=x.y.z BUILD=b
#   git push origin x.y.z-b (or to snoopy for review)
#
# Build and release:
#
#   make VERSION=x.y.z REPO=snoopycrimecop
#

RELEASE = $(shell date)

SHELL = bash

REPO ?= openmicroscopy
ORIGIN ?= origin

release:
ifndef VERSION
	$(error VERSION is undefined)
endif

	perl -i -pe 's/OMERO_VERSION=(\S+)/OMERO_VERSION=$(VERSION)/' Dockerfile
	perl -i -pe 's/(org.openmicroscopy.release-date=)"([^"]+)"/$$1"$(RELEASE)"/' Dockerfile

ifndef BUILD
	git commit -a -m "Bump OMERO_VERSION to $(VERSION)"
	git tag -s -m "Tag version $(VERSION)" $(VERSION)
else
	git commit -a -m "Re-build $(BUILD) of OMERO_VERSION $(VERSION)"
	git tag -s -m "Re-tag $(VERSION) with suffix $(BUILD)" $(VERSION)-$(BUILD)
endif


remote:
ifndef VERSION
	$(error VERSION is undefined)
endif

ifndef BUILD
	git push $(ORIGIN) $(VERSION)
else
	git push $(ORIGIN) $(VERSION)-$(BUILD)
endif


build:
ifndef VERSION
	$(error VERSION is undefined)
endif
	docker build -t $(REPO)/omero-server:latest .
	docker tag $(REPO)/omero-server:latest $(REPO)/omero-server:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker tag $(REPO)/omero-server:latest $(REPO)/omero-server:$$MAJOR_MINOR

push:
ifndef VERSION
	$(error VERSION is undefined)
endif
	docker push $(REPO)/omero-server:latest
	docker push $(REPO)/omero-server:$(VERSION)
	@MAJOR_MINOR=$(shell echo $(VERSION) | cut -f1-2 -d. );\
	docker push $(REPO)/omero-server:$$MAJOR_MINOR
