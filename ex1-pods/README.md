# Exercise 1: Pods and kubectl basics

This exercise demonstrates a two-container Pod, communication over the Pod's
shared network namespace, temporary shared storage, container restarts, and the
difference between a restarted container and a recreated Pod.

Run all commands from the repository root.

## 1. Check the cluster

Confirm that kubectl is targeting the local kind cluster:

```bash
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
kubectl get namespaces
```

The expected context is `kind-k8s-exercises`, with one Ready control-plane
node.

Explore the cluster and its built-in API documentation:

```bash
kubectl get pods -A
kubectl get pods -n kube-system -o wide
kubectl api-resources
kubectl explain pod.spec.containers
```

## 2. Create the namespace and healthy Pod

```bash
kubectl apply -f ex1-pods/namespace.yaml
kubectl apply -f ex1-pods/nginx-pod.yaml
kubectl get pod nginx-pod -n ex1 --watch
```

Stop the watch with Ctrl-C after the Pod reports `2/2 Running`.

Inspect scheduling, networking, container state, and Events:

```bash
kubectl get pod nginx-pod -n ex1 -o wide
kubectl describe pod nginx-pod -n ex1
kubectl get pod nginx-pod -n ex1 -o yaml
```

## 3. Inspect nginx

Follow nginx's access log:

```bash
kubectl logs nginx-pod -c nginx -n ex1 --follow
```

The curl container requests `localhost` every five seconds, so nginx should log
a successful request every five seconds. This works because both containers
share the Pod's network namespace, including its IP address and loopback
interface.

In another terminal, inspect each container:

```bash
kubectl logs nginx-pod -c curl -n ex1 --tail=20
kubectl exec nginx-pod -c nginx -n ex1 -- hostname
kubectl exec nginx-pod -c nginx -n ex1 -- cat /etc/hosts
kubectl exec nginx-pod -c nginx -n ex1 -- env
kubectl exec -it nginx-pod -c nginx -n ex1 -- sh
```

Inside the shell, inspect `/etc/nginx/`, then type `exit`.

To access nginx from the workstation, run this in one terminal:

```bash
kubectl port-forward pod/nginx-pod 8080:80 -n ex1
```

Then run this in another terminal:

```bash
curl http://localhost:8080
```

The request should appear in the nginx access log.

## 4. Prove that the containers share an emptyDir volume

Write a file from the curl container:

```bash
kubectl exec nginx-pod -n ex1 -c curl -- \
  sh -c 'echo "written by curl" > /shared/message.txt'
```

Read the same file from nginx:

```bash
kubectl exec nginx-pod -n ex1 -c nginx -- \
  cat /shared/message.txt
```

The file is visible in both containers because they mount the same `emptyDir`.
It survives an individual container restart but is deleted when the Pod is
deleted.

## 5. Explore mutable and immutable Pod fields

Record the Pod UID and current image:

```bash
kubectl get pod nginx-pod -n ex1 \
  -o jsonpath='{.metadata.uid}{" image="}{.spec.containers[0].image}{"\n"}'
```

Pod container images are one of the few mutable fields. Temporarily change the
live image, then reapply the committed manifest:

```bash
kubectl set image pod/nginx-pod nginx=nginx:1.27 -n ex1
kubectl get pod nginx-pod -n ex1 --watch
kubectl apply -f ex1-pods/nginx-pod.yaml
kubectl get pod nginx-pod -n ex1 \
  -o jsonpath='{.metadata.uid}{" image="}{.spec.containers[0].image}{"\n"}'
```

Stop the watch after the container is Running again. The UID stays the same:
the kubelet restarted the nginx container, but Kubernetes did not recreate the
Pod object.

Attempt to change the curl container's command:

```bash
kubectl patch pod nginx-pod -n ex1 --type=json \
  -p='[{"op":"replace","path":"/spec/containers/1/command","value":["sh","-c","sleep 3600"]}]'
```

The API rejects this update because a container command is immutable on an
existing Pod.

## 6. Observe CrashLoopBackOff and restartCount

```bash
kubectl apply -f ex1-pods/crash-pod.yaml
kubectl get pod crash-pod -n ex1 --watch
```

The curl container exits with status 1. With `restartPolicy: Always`, kubelet
restarts it repeatedly and increases `restartCount`; the delay between attempts
eventually appears as `CrashLoopBackOff`.

Stop the watch and diagnose it:

```bash
kubectl get pod crash-pod -n ex1 \
  -o jsonpath='{range .status.containerStatuses[*]}{.name}{" restarts="}{.restartCount}{" state="}{.state}{" lastState="}{.lastState}{"\n"}{end}'
kubectl describe pod crash-pod -n ex1
kubectl logs crash-pod -c curl -n ex1
kubectl logs crash-pod -c curl -n ex1 --previous
```

This is a container restart inside one Pod, not Pod recreation.

## 7. Prove that a bare Pod is not self-healing

Record the healthy Pod's UID, delete it, and wait briefly:

```bash
kubectl get pod nginx-pod -n ex1 -o jsonpath='{.metadata.uid}{"\n"}'
kubectl delete pod nginx-pod -n ex1
kubectl get pods -n ex1 --watch
```

Stop the watch after confirming `nginx-pod` does not return. A bare Pod has no
controller responsible for recreating it.

Recreate it from the committed manifest and compare its new UID:

```bash
kubectl apply -f ex1-pods/nginx-pod.yaml
kubectl wait --for=condition=Ready pod/nginx-pod -n ex1 --timeout=60s
kubectl get pod nginx-pod -n ex1 -o jsonpath='{.metadata.uid}{"\n"}'
```

The replacement has a new UID and its container restart counters begin again at
zero.

## 8. Imperative debugging and YAML generation

Create an ephemeral debugging Pod. It is automatically deleted when its command
finishes:

```bash
kubectl run test --image=busybox:1.36 --restart=Never --rm -it -n ex1 -- sh
```

Inside it, try `nslookup kubernetes.default.svc.cluster.local`, then type `exit`.

Generate a YAML skeleton without creating a resource:

```bash
kubectl run demo --image=nginx --dry-run=client -o yaml
```

Generated YAML is useful as a starting point, but committed manifests remain the
reviewable source of truth.

## 9. Troubleshooting sequence

When a Pod does not behave as expected, inspect its status, Events, and logs in
that order:

```bash
kubectl get pods -n ex1
kubectl describe pod nginx-pod -n ex1
kubectl get events -n ex1 --sort-by=.lastTimestamp
kubectl logs nginx-pod -c nginx -n ex1
kubectl logs nginx-pod -c curl -n ex1 --previous
```

## 10. Cleanup

Deleting the namespace removes both Pods and all other namespaced Exercise 1
resources:

```bash
kubectl delete namespace ex1
```
