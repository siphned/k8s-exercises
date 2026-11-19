# Exercise 2 — Deployments and Services

## Show demo

Create the local kind cluster with the committed host-to-NodePort mapping if it does
not already exist:

```sh
kind create cluster --name k8s-exercises --config kind-config.yaml
```

Run the complete good rollout, broken rollout, availability check, and rollback:

```sh
./ex2-deployments/rollout-demo.sh
```

The script demonstrates that the unavailable `nginx:1.99` Pod enters
`ImagePullBackOff` while all three old Pods remain Ready and continue serving through
the NodePort. It then runs `kubectl rollout undo`, verifies that the image is back to
`nginx:1.27`, and reapplies the committed healthy manifest to reconcile declarative
state.

Verify the final Service and its three endpoints from inside and outside the cluster:

```sh
kubectl get service web -n ex2
kubectl get endpointslices -n ex2 \
  -l kubernetes.io/service-name=web -o wide
curl http://127.0.0.1:32142/
```

Actual rollout history after the demo:

```text
deployment.apps/web-deploy
REVISION  CHANGE-CAUSE
2         Attempt rollout with unavailable nginx:1.99 image
3         Restore nginx:1.27 with RollingUpdate after Recreate test
```

Explain from the observed rollout that `maxSurge: 1` permits one extra Pod while
`maxUnavailable: 0` keeps all three healthy replicas available until a replacement is
Ready.

## Cleanup

```sh
kubectl delete namespace ex2
kubectl get namespace ex2
```

The final command should report that namespace `ex2` was not found, confirming that
its Deployment, ReplicaSets, Pods, and Services were removed with it.
