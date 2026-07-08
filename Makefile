REGISTRY ?= asia-docker.pkg.dev/bucketeer-io/bucketeer
IMAGE    ?= robusta-runner
TAG      ?= 0.43.0-bkt
ENV_TYPE ?= PRODUCTION
PLATFORM ?= linux/amd64
NAMESPACE ?= observability

.PHONY: docker-build docker-push deploy rollout-status clean

## Build the runner image from source (this fork), for linux/amd64
docker-build:
	docker build --platform $(PLATFORM) \
		--build-arg ENV_TYPE=$(ENV_TYPE) \
		--build-arg RUNNER_VERSION=$(TAG) \
		-t $(IMAGE):$(TAG) .

## Push the image to Artifact Registry
docker-push: docker-build
	docker tag $(IMAGE):$(TAG) $(REGISTRY)/$(IMAGE):$(TAG)
	docker push $(REGISTRY)/$(IMAGE):$(TAG)

## Deploy to the current kubectl context (imperative; prefer Helm values for GitOps)
deploy:
	kubectl -n $(NAMESPACE) set image deploy/robusta-runner \
		runner=$(REGISTRY)/$(IMAGE):$(TAG)
	kubectl -n $(NAMESPACE) rollout status deploy/robusta-runner --timeout=120s

## Show the currently deployed runner image
rollout-status:
	kubectl -n $(NAMESPACE) get deploy/robusta-runner \
		-o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'

## Remove locally built image tags
clean:
	docker rmi $(IMAGE):$(TAG) $(REGISTRY)/$(IMAGE):$(TAG) 2>/dev/null || true
