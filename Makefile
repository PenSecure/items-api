# Local developer shortcuts. CI runs the same checks (see .github/workflows).
IMAGE      ?= items-api
TAG        ?= local
OVERLAY    ?= local
K8S_VER    ?= 1.30.0
TF_DIRS    := terraform/bootstrap terraform/envs/dev terraform/modules/ecr \
              terraform/modules/github-oidc-role terraform/modules/state-bucket

.PHONY: help run lint test build scan k8s-validate kind-up kind-deploy kind-down tf-check

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-14s %s\n", $$1, $$2}'

run: ## Run the API locally on :8080
	cd app && go run ./cmd/server

lint: ## Go, Dockerfile and dockerignore checks
	cd app && golangci-lint run ./...
	hadolint docker/Dockerfile
	diff -u docker/Dockerfile.dockerignore .dockerignore

test: ## Unit tests with race detector
	cd app && go test -race -cover ./...

build: ## Build the container image
	docker build -f docker/Dockerfile --build-arg VERSION=$(TAG) -t $(IMAGE):$(TAG) .

scan: build ## Trivy scan the local image (fails on fixable HIGH/CRITICAL)
	trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 $(IMAGE):$(TAG)

k8s-validate: ## Render every overlay and validate against the K8s schema
	@for o in k8s/overlays/*/; do echo "== $$o"; kustomize build $$o | kubeconform -strict -summary -kubernetes-version $(K8S_VER); done

kind-up: ## Create a kind cluster with Calico (enforces NetworkPolicy) and ingress-nginx
	kind create cluster --name items-api --config hack/kind-config.yaml
	kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/calico.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/kind/deploy.yaml
	kubectl -n kube-system rollout status ds/calico-node --timeout=180s
	kubectl -n ingress-nginx rollout status deploy/ingress-nginx-controller --timeout=180s

kind-deploy: build ## Load the image into kind and apply an overlay
	kind load docker-image $(IMAGE):$(TAG) --name items-api
	kubectl apply -k k8s/overlays/$(OVERLAY)
	kubectl -n items-api rollout status deploy/items-api --timeout=120s

kind-down: ## Delete the kind cluster
	kind delete cluster --name items-api

tf-check: ## fmt, validate and test every Terraform directory (no AWS needed)
	terraform fmt -check -recursive terraform
	@for d in $(TF_DIRS); do echo "== $$d"; (cd $$d && terraform init -backend=false -input=false >/dev/null && terraform validate && { ls tests/*.tftest.hcl >/dev/null 2>&1 && terraform test || true; }) || exit 1; done
