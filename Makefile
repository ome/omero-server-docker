#
# Usage:
#
#   make VERSION=5.x.y
#   git push origin 5.x.y (or to snoopy for review)
#
release:
ifndef VERSION
	$(error VERSION is undefined)
endif
	sed -i -e 's/OMERO_VERSION=latest/OMERO_VERSION=$(VERSION)/' Dockerfile
	git commit -a -m "Bump version to $(VERSION)"
	git tag -s -m "Bump version to $(VERSION)" $(VERSION)
