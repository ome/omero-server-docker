RELEASE = $(shell date)
COMMIT = $(shell git rev-parse HEAD || echo -n NOTGIT)

SHELL = bash

REPO ?= openmicroscopy
ORIGIN ?= origin

usage:
	@echo "Usage:"
	@echo " "
	@echo "  make VERSION=x.y.z tag                            #   Update Dockerfile, commit and tag"
	@echo "  make VERSION=x.y.z BUILD=1 tag                    #   Re-tag, e.g. when a new upstream is released"
	@echo " "
	@echo "  # Release Candidate"
	@echo "  make VERSION=x.y.z ORIGIN=snoopycrimecop remote   #   Push to another git remote"
	@echo "  make VERSION=x.y.z REPO=snoopycrimecop build      #   Build and tag images for another hub account"
	@echo "  make VERSION=x.y.z REPO=snoopycrimecop push       #   Push images to another hub account"
	@echo " "
	@echo "  # Release"
	@echo "  make VERSION=x.y.z remote                         #   Push to $(ORIGIN)"
	@echo "  make VERSION=x.y.z build                          #   Build and tag images for $(REPO) hub repo"
	@echo "  make VERSION=x.y.z push                           #   Push images to $(REPO) hub repo"

tag:
ifndef VERSION
	$(error VERSION is undefined)
endif

	perl -i -pe 's/OMERO_VERSION=(\S+)/OMERO_VERSION=$(VERSION)/' Dockerfile
	perl -i -pe 's/(org.openmicroscopy.release-date=)"([^"]+)"/$$1"$(RELEASE)"/' Dockerfile
	perl -i -pe 's/(org.openmicroscopy.commit=)"([^"]+)"/$$1"$(COMMIT)"/' Dockerfile

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
