#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

deployment=web-deploy
namespace=ex2

recover() {
  kubectl apply -f ex2-deployments/web-deploy.yaml >/dev/null
}
trap recover EXIT

echo "Applying the healthy Deployment and NodePort Service"
kubectl apply -f ex2-deployments/namespace.yaml
kubectl delete "deployment/$deployment" -n "$namespace" \
  --ignore-not-found --wait=true
kubectl apply -f ex2-deployments/web-deploy.yaml
kubectl apply -f ex2-deployments/web-svc-nodeport.yaml
kubectl rollout status "deployment/$deployment" -n "$namespace" --timeout=120s

echo "Applying the unavailable nginx:1.99 image"
kubectl apply -f ex2-deployments/web-deploy-bad.yaml
if kubectl rollout status "deployment/$deployment" -n "$namespace" --timeout=15s; then
  echo "Error: the intentionally broken rollout unexpectedly succeeded" >&2
  exit 1
fi

echo "The failed new Pod and old Ready Pods are visible together"
kubectl get deployment,replicaset,pod -n "$namespace"

echo "The old Pods remain Service endpoints and continue serving requests"
kubectl get endpointslices -n "$namespace" \
  -l kubernetes.io/service-name=web -o wide
curl --fail --silent --show-error --max-time 5 http://127.0.0.1:32142/ >/dev/null

echo "Rolling back to the previous healthy revision"
kubectl rollout undo "deployment/$deployment" -n "$namespace"
kubectl rollout status "deployment/$deployment" -n "$namespace" --timeout=120s

echo "Reconciling the rollback with the committed healthy manifest"
kubectl apply -f ex2-deployments/web-deploy.yaml

image=$(kubectl get "deployment/$deployment" -n "$namespace" \
  -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$image" != "nginx:1.27" ]]; then
  echo "Error: rollback restored $image instead of nginx:1.27" >&2
  exit 1
fi

kubectl rollout history "deployment/$deployment" -n "$namespace"
kubectl get deployment,pod -n "$namespace"

trap - EXIT
echo "Rollback demo completed successfully"
