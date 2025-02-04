.PHONY: container

CONTAINER_IMAGE=ghcr.io/mstergianis/portfolio:latest

container: Containerfile 
	podman build . -t ${CONTAINER_IMAGE}
	podman push ${CONTAINER_IMAGE}
