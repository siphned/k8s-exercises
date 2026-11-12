# YAML files
- take care to indent everything properly, otherwise stuff breaks easily
- indentation is two spaces wide(!)

# `kubectl`
- as a CLI it is supposedly the most in control you can be while talking to the API, the downside is you have to learn it
- Pods are immutable in some fields, so to add another container (1.3), we have to create a new one (delete and recreate)

# Q&A
- why does `localhost` work across containers?
  - The containers are running inside the same Pod, so they share the same Pod IP; which in turn means they also share the same `lo`, `localhost`, network ports

- which pod fields are immutable?
  - Changing fields other than a select few [`spec.containers[*].image`, `spec.initContainers[*].image`, `spec.activeDeadlineSeconds`, `spec.tolerations` (only additions to existing tolerations), `spec.terminationGracePeriodSeconds` (allowing it to be set to 1 if it was previously negative)] is not allowed; the other Pod fields are immutable.

- `restartCount` vs recreation
  - `restartCount` increasing means that kubelet restarted a container inside the same Pod. Pod recreation produces a new Pod object and resets its container status, even if the replacement Pod uses the same name.

- `restartPolicy: Always` restarts the intentionally failing container in `crash-pod.yaml`. Repeated non-zero exits eventually produce `CrashLoopBackOff`, which is a delay between restart attempts rather than a separate kind of crash.

- what does each component in `kube-system` do?
  - `coredns` provides DNS-based service discovery. Pods can use names such as `kubernetes.default.svc.cluster.local` instead of remembering ClusterIPs.
  - `kube-proxy` runs on every node and installs network rules that direct Service traffic to matching Pod endpoints.
  - `kindnet` is this kind cluster's CNI implementation. It configures Pod networking so Pods receive IP addresses and can communicate across the cluster.
  - `kube-apiserver` exposes the Kubernetes API used by `kubectl` and by the other control-plane components.
  - `etcd` stores the cluster's desired and observed state.
  - `kube-scheduler` chooses a suitable node for each unscheduled Pod.
  - `kube-controller-manager` runs reconciliation controllers that continually move actual cluster state toward the declared desired state.
