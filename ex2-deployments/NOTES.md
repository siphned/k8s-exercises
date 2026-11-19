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
