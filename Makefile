DOCKER = docker

DEBIAN_ASDF_TAG ?= $(shell docker run --rm gcr.io/go-containerregistry/crane ls dex4er/debian-asdf | grep -P '^asdf-[0-9.]+-' | sort -r -t- | head -n1)
TERRAFORM_RELEASE ?= $(shell cat .tool-versions | awk '$$1 == "terraform" { print $$2 }')
VERSION ?= $(shell cat .tool-versions | while read plugin version; do echo -n "$$plugin-$$version-"; done)$(DEBIAN_ASDF_TAG)

REVISION ?= $(shell git rev-parse HEAD)
BUILDDATE ?= $(shell TZ=GMT date '+%Y-%m-%dT%R:%S.%03NZ')

IMAGE_NAME ?= debian-asdf-terraform
LOCAL_REPO ?= localhost:5000/$(IMAGE_NAME)
DOCKER_REPO ?= localhost:5000/$(IMAGE_NAME)

.PHONY: help
help:
	@echo "$(IMAGE_NAME)"
	@echo
	@echo Targets:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9._-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

define print-target
	@printf "Executing target: \033[36m$@\033[0m\n"
endef

.PHONY: all
all: build push
all: ## Build and push.

.PHONY: build
build: ## Build a local image without publishing artifacts.
	$(call print-target)
	$(DOCKER) build \
	--squash \
	--build-arg DEBIAN_ASDF_TAG=$(DEBIAN_ASDF_TAG) \
	--build-arg VERSION=$(VERSION) \
	--build-arg REVISION=$(REVISION) \
	--build-arg BUILDDATE=$(BUILDDATE) \
	--tag $(LOCAL_REPO) \
	.

.PHONY: push
push: ## Publish to container registry.
	$(call print-target)
	$(DOCKER) tag $(LOCAL_REPO) $(DOCKER_REPO):$(VERSION)
	$(DOCKER) push $(DOCKER_REPO):$(VERSION)
	$(DOCKER) tag $(LOCAL_REPO) $(DOCKER_REPO):terraform-$(TERRAFORM_RELEASE:v%=%)
	$(DOCKER) push $(DOCKER_REPO):terraform-$(TERRAFORM_RELEASE:v%=%)
	$(DOCKER) tag $(LOCAL_REPO) $(DOCKER_REPO):latest
	$(DOCKER) push $(DOCKER_REPO):latest

.PHONY: test
test: ## Test local image
	$(call print-target)
	$(DOCKER) run --rm -t $(LOCAL_REPO) bash -c "asdf version" | grep ^v
	$(DOCKER) run --rm -t ${LOCAL_REPO} aws --version | grep ^aws-cli/
	$(DOCKER) run --rm -t ${LOCAL_REPO} infracost --version | grep ^Infracost
	$(DOCKER) run --rm -t ${LOCAL_REPO} terraform --version | grep ^Terraform
	$(DOCKER) run --rm -t ${LOCAL_REPO} tf version | grep ^tf

.PHONY: update
update: ## Update asdf tools.
	$(call print-target)
	cat .tool-versions | while read app version; do \
		asdf install $$app latest; \
		asdf local $$app latest; \
	done

.PHONY: info
info: ## Show information about version
	@echo "Version:           ${VERSION}"
	@echo "Revision:          ${REVISION}"
	@echo "Build date:        ${BUILDDATE}"
