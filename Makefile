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

RELEASE = $(shell date)

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
