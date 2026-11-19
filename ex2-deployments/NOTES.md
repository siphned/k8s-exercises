# Q&A
- 2.1
  - "Draw the ownership chain Deployment → ReplicaSet → Pod"
    - Deployment: web
      └── ReplicaSet: web-865b5674c
          ├── Pod: web-865b5674c-<pod-id>
          ├── Pod: web-865b5674c-<pod-id>
          └── Pod: web-865b5674c-<pod-id>
  - step 4
    - deleted Pods, and ReplicaSets are automatically recreated and launched seamlessly, in contrast to Deployments which are not recreated

- 2.2
  - step 1: upon changing replica count and applying the already active ReplicaSet adapts to the new requirements
  - step 2: "Why is this a reason to never scale imperatively in a git-managed cluster?"
    - manual scaling can be useful temporarily, however production changes should update the declared replica count through the normal reviewed workflow, so Git and the cluster have a clear, shared desired state

- 2.3
  - step 4: changing one Pod's label from `app: web` to `app: web-old`
    - the relabelled Pod no longer matches the ReplicaSet's selector, so the ReplicaSet creates a replacement to maintain 3 matching replicas. The original Pod keeps running, making 4 Pods in total, but it is no longer selected by the Service either.
  - step 5: changing the Service selector to a label no Pod has
    - the nginx Pods kept running, but the Service had no matching backends, so a request from the debug Pod failed with `connection refused`. Reverting the selector in Git restored `app: web` in the manifest; the corrected manifest still has to be applied for the live Service to use it.
  - step 6: testing Service access
    - a temporary Pod in a different namespace could reach the Service with `wget`. Namespaces scope Kubernetes resources but do not isolate Pod networking, so this verifies in-cluster Service access, not access from outside the cluster.
    - changing the Service to `NodePort` made Kubernetes allocate a port from the default NodePort range. The Service had three endpoints and returned the nginx welcome page when requested from a temporary container on the kind Docker network.
    - requesting the NodePort through the kind node IP from WSL timed out. The kind node runs as a Docker container, and `docker port k8s-exercises-control-plane` showed that only the Kubernetes API port was published to the host. A NodePort listens on the Kubernetes node, but kind does not automatically publish that container port to the host.
    - running `kubectl port-forward -n ex2 service/web 8080:80` made the Service reachable from the WSL host at `http://localhost:8080`. This confirms the Service works through the Kubernetes API tunnel, but does not expose the NodePort on the host.
    - added `kind-config.yaml` with an `extraPortMappings` entry from host port `32142` to container port `32142`. The NodePort manifest also pins `nodePort: 32142`, because the Docker mapping and the Service must use the same node port.
    - kind only applies `extraPortMappings` while creating a cluster, so the local cluster was recreated and the exercise resources were restored:
      - `kind delete cluster --name k8s-exercises`
      - `kind create cluster --name k8s-exercises --config kind-config.yaml`
      - `kubectl apply -f ex2-deployments/namespace.yaml`
      - `kubectl apply -f ex2-deployments/web-deploy.yaml`
      - `kubectl apply -f ex2-deployments/web-svc-nodeport.yaml`
      - `kubectl rollout status deployment/web-deploy -n ex2 --timeout=120s`
    - after recreating the cluster, `curl http://127.0.0.1:32142/` returned the nginx welcome page from WSL without using port-forwarding. The request path is host port `32142` → kind node container port `32142` → NodePort Service → one of the selected nginx Pods.

- 2.4
  - step 1: `RollingUpdate` strategy
    - while watching the Pods in a separate terminal after applying the manifest changes, I could see that at any time there were at least 3 Pods running, and at some points 4, which matches the expectations given by the `RollingUpdate` strategy options we have chosen: `maxSurge: 1` dictates that there can be at most 1 extra Pod active above the desired state while `maxUnavailable: 0` states that there cannot be any less than the desired state of 3.
  - step 3: `change-cause` annotation
    - useful for planned changes in manifest which require applying it again, when inspecting the rollout history, the change cause is listed, and can be tracked
  - step 4: change nginx version to a non-existent one
    - the new Pods could not start and never became Ready, so the rolling update kept the three old healthy Pods running to satisfy `maxUnavailable: 0`. The rollout stalled because Kubernetes could not safely replace them.
    - Kubernetes did not give up after the first attempts: it continued retrying the image pull with increasing delays, shown as `ErrImagePull` and `ImagePullBackOff`. A Deployment does not automatically roll back; after its progress deadline it reports a failed rollout while the old Pods continue serving traffic.
  - step 6: change the Deployment strategy to `Recreate`
    - after changing the strategy to `Recreate`, Kubernetes terminated all old healthy Pods before starting their replacements. Because the replacement image did not exist, the new Pod objects remained in `ErrImagePull` or `ImagePullBackOff`, leaving zero Ready and available Pods and no healthy endpoints for the Service.
    - this demonstrates the availability tradeoff between the strategies: `RollingUpdate` can preserve the previous healthy replicas during a failed release, while `Recreate` causes downtime because it removes the old version before verifying that the new version can start.
    - after the test, the manifest was restored to `RollingUpdate` with the valid `nginx:1.27` image so that the exercise ends with three healthy replicas.

- 2.5
  - a Service does not care whether its Pods were created by a Deployment, StatefulSet, or by hand because it does not inspect their ownership chain. Its selector discovers matching Pods and records them in EndpointSlices, while readiness determines which endpoints normally receive traffic. The workload controller maintains the Pods independently from the Service discovering its backends.
