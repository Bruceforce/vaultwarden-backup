#!/bin/sh

#set -xe

### Functions

build() {
    docker buildx build \
        --push \
        --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
        "$@" .
}

if [ $# -ne 1 ]; then exit 1; fi

TAG="$1"

# Gitlab tag
docker login -u "$CI_REGISTRY_USER" -p "$CI_REGISTRY_PASSWORD" "$CI_REGISTRY"
set -- --tag "$CI_REGISTRY_IMAGE:$TAG"

# Docker hub tag
if [ -n "$CI_REGISTRY_USER" ] && [ -n "$DOCKERHUB_PASSWORD" ] && [ -n "$DOCKERHUB_REGISTRY" ]&& [ -n "$DOCKERHUB_USER" ]&& [ -n "$DOCKERHUB_REPO" ]; then
    docker login -u "$DOCKERHUB_USER" -p "$DOCKERHUB_PASSWORD" "$DOCKERHUB_REGISTRY"
    set -- "$@" --tag "$DOCKERHUB_USER/$DOCKERHUB_REPO:$TAG"
    # Used to update deprecated image
    set -- "$@" --tag "$DOCKERHUB_USER/bw_backup:$TAG"
fi

build "$@"