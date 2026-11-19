# Q&A
- 2.1 
  - "Draw the ownership chain Deployment → ReplicaSet → Pod"
    - Deployment: web-deploy
      └── ReplicaSet: web-deploy-865b5674c
          ├── Pod: web-deploy-865b5674c-k8vgk
          ├── Pod: web-deploy-865b5674c-n4j8w
          └── Pod: web-deploy-865b5674c-nckf5
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
    - changing the Service to `NodePort` assigned port `32472`. The Service had three endpoints and returned the nginx welcome page when requested from a temporary container on the kind Docker network at `172.18.0.2:32472`. The WSL host could not reach that node IP because this kind cluster does not publish the NodePort to the host; host access requires a kind `extraPortMappings` configuration when creating the cluster.
    - running `kubectl port-forward -n ex2 service/web 8080:80` made the Service reachable from the WSL host at `http://localhost:8080`. This confirms the Service works through the Kubernetes API tunnel, but does not expose the NodePort on the host.
