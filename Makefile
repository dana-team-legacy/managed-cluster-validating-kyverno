NAME ?= kyverno
REPOSITORY ?= kyverno
KYVERNO-HELM ?= "https://kyverno.github.io/$(NAME)/"

NAMESPACE ?= kyverno

.PHONY: add
add: helm
	$(LOCALBIN)/helm repo add $(REPOSITORY) $(KYVERNO-HELM)

.PHONY: template
template: add
## Use the securityContext=null flag for OpenShift usage, as explained in the 
## Kyverno installation guide (https://kyverno.io/docs/installation/#notes-for-openshift-users)
	$(LOCALBIN)/helm template $(NAME) $(REPOSITORY)/$(NAME) --output-dir $(MANIFESTS) --set securityContext=null --set replicaCount=3 --set namespace=$(NAMESPACE) --create-namespace --namespace $(NAMESPACE)

.PHONY: patch-node
patch-node: template
## In order to allow Kyverno policies on nodes, we need to
## remove the Node filter from the Kyverno ConfigMap
	sed -i 's/\[Node,\*,\*\]//g' $(MANIFESTS)/$(NAME)/templates/configmap.yaml

.PHONY: build
build: template
	echo -n > $(MANIFESTS)/kyverno.yml
	cat $(MANIFESTS)/namespace.yaml >> $(MANIFESTS)/kyverno.yaml
	for f in $(MANIFESTS)/$(NAME)/templates/*.yaml ; do cat $$f >> $(MANIFESTS)/kyverno.yml ; done

##@ Build Dependencies

## Location to install dependencies to
LOCALBIN ?= $(shell pwd)/bin
$(LOCALBIN):
	mkdir -p $(LOCALBIN)

## Location to put manifests in
MANIFESTS ?= $(shell pwd)/manifests
$(MANIFESTS):
	mkdir -p $(MANIFESTS)

## Tool Versions
HELM_VERSION ?= v3.10.3

## Tool Binaries
HELM ?= $(LOCALBIN)/helm
HELM_BINARY ?= linux-amd64

HELM_DOWNLOAD ?= "https://get.helm.sh/helm-$(HELM_VERSION)-$(HELM_BINARY).tar.gz"

.PHONY: helm
helm: $(HELM) ## Download helm locally if necessary.
$(HELM): $(LOCALBIN)
	test -s $(LOCALBIN)/helm || { wget -q $(HELM_DOWNLOAD) && tar -zxf helm-$(HELM_VERSION)-$(HELM_BINARY).tar.gz && mv $(HELM_BINARY)/helm $(LOCALBIN)/helm && rm -rf linux-amd64 helm-$(HELM_VERSION)-$(HELM_BINARY).tar.gz; }