### Vars ###
CURRENT_DIR= $(shell pwd)
BUILDX_VERSION = v0.7.1
BUILDX_ARCH = linux-amd64

### Targets ###
test-shellcheck:
	docker run --rm -v $(CURRENT_DIR)/src:/src --workdir /src --env-file .env koalaman/shellcheck-alpine sh -c 'shellcheck /src/usr/local/bin/*.sh /src/opt/scripts/*.sh /src/app/*.sh'
test-release:
	docker run --rm -v $(CURRENT_DIR):/app --workdir /app --env-file .env node:lts-alpine sh -c '\
		apk add git && \
		npm install -g semantic-release conventional-changelog-conventionalcommits @semantic-release/changelog @semantic-release/git @semantic-release/gitlab && \
		semantic-release -d --dry-run --no-ci -r https://gitlab.com/1O/bitwarden_rs-backup'
test-build:
	docker network create build-network 2>&1 | true
	docker run -d --rm --privileged --name dind \
		--network build-network --network-alias docker \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v $(CURRENT_DIR)/test/build-certs:/certs \
		-v $(CURRENT_DIR)/test/build-certs:/certs/client \
		docker:dind --experimental 2>&1 | true
	docker run --rm --privileged --name builder \
		--network build-network \
		-e DOCKER_TLS_CERTDIR=/certs \
		-v $(CURRENT_DIR)/test/build-certs:/certs/client \
		-v $(CURRENT_DIR)/test/builds:/builds \
		-v $(CURRENT_DIR):/app --workdir /app \
		docker:latest sh -c '\
		apk add curl \
    	&& mkdir -p ~/.docker/cli-plugins \
		&& curl -sSLo ~/.docker/cli-plugins/docker-buildx https://github.com/docker/buildx/releases/download/$(BUILDX_VERSION)/buildx-$(BUILDX_VERSION).$(BUILDX_ARCH) \
    	&& chmod +x ~/.docker/cli-plugins/docker-buildx \
    	&& docker run --rm --privileged multiarch/qemu-user-static --reset -p yes \
    	&& docker context create my-context \
    	&& docker buildx create --use my-context \
    	&& docker info \
		&& docker buildx build --progress plain --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag vaultwarden-backup -o /builds .'
	docker stop dind
	docker network rm build-network
build:
	docker build -t bruceforce/vaultwarden-backup $(CURRENT_DIR)