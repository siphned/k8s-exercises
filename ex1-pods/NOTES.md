# YAML files
- take care to indent everything properly, otherwise stuff breaks easily
- indentation is two spaces wide(!)

# `kubectl`
- as a CLI it is supposedly the most in control you can be while talking to the API, the downside is you have to learn it
- Pods are somewhat immutable, so to add another container (1.3), we have to create a new one (delete and recreate)

# Q&A
- Q: "Note:  localhost  works across containers — why?"
  A: The containers are running inside the same Pod, so they share the same Pod IP; which in turn means they also share the same `lo`, `localhost`, network ports
- ad 1.4 -- changing the `nginx` image did not recreate the Pod object, but the kubelet restarted the `nginx` container with the new image. Changing fields other than a select few [`spec.containers[*].image`, `spec.initContainers[*].image`, `spec.activeDeadlineSeconds`, `spec.tolerations` (only additions to existing tolerations), `spec.terminationGracePeriodSeconds` (allowing it to be set to 1 if it was previously negative)] is not allowed; the other Pod fields are immutable.
- `restartCount` increasing means that kubelet restarted a container inside the same Pod. Pod recreation produces a new Pod object and resets its container status, even if the replacement Pod uses the same name.
- `restartPolicy: Always` restarts the intentionally failing container in `crash-pod.yaml`. Repeated non-zero exits eventually produce `CrashLoopBackOff`, which is a delay between restart attempts rather than a separate kind of crash.
