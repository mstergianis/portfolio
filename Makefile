.PHONY: container build push

CONTAINER_IMAGE=ghcr.io/mstergianis/portfolio:latest

container: build push

build:
	podman build . -t ${CONTAINER_IMAGE}

push:
	podman push ${CONTAINER_IMAGE}
