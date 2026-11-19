# Q&A
- 2.1 "Draw the ownership chain Deployment → ReplicaSet → Pod"
  - Deployment: web-deploy
    └── ReplicaSet: web-deploy-865b5674c
        ├── Pod: web-deploy-865b5674c-k8vgk
        ├── Pod: web-deploy-865b5674c-n4j8w
        └── Pod: web-deploy-865b5674c-nckf5

- 2.1 step 4
  - deleted Pods, and ReplicaSets are automatically recreated and launched seamlessly, in contrast to Deployments which are not recreated

- 2.2
  - upon changing replica count and applying the already active ReplicaSet adapts to the new requirements