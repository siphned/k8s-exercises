# Kubernetes onboarding exercises

Kubernetes onboarding exercises — manifests, notes and scripts.

Each exercise builds on the previous one, from creating a single Pod to
performing day-2 cluster operations. Work is organized so that every
manifest can be reviewed, reproduced, and applied from this repository.

## Prerequisites

- `kubectl` installed and available on your `PATH`
- `kind` installed and available on your `PATH`
- A container registry, when an exercise requires a custom image

This repository uses [kind](https://kind.sigs.k8s.io/) for local Kubernetes
clusters. The exercises were prepared with `kind v0.34.0-alpha` and
`kubectl v1.36.1`; minor version differences should normally be acceptable.

Create the single-node cluster used by Exercises 1–4:

```bash
kind create cluster --name k8s-exercises
kubectl cluster-info
kubectl get nodes
```

If the cluster already exists, select its kubeconfig context instead:

```bash
kubectl config use-context kind-k8s-exercises
kubectl cluster-info
```

## Repository layout

```text
.
├── README.md
├── ex1-pods/
├── ex2-deployments/
├── ex3-config/
├── ex4-stateful/
│   └── app/
└── ex5-operations/
    └── chart/
```

Each exercise directory contains its manifests, a `README.md` with the
demonstration steps, and a short `NOTES.md` file with observations and review
questions.

## Running an exercise

Work in the namespace assigned to the exercise. Create it before applying
manifests:

```bash
kubectl create namespace ex1
kubectl config set-context --current --namespace=ex1
```

Apply manifests from the corresponding exercise directory:

```bash
kubectl apply -f ex1-pods/
kubectl get all
```

Use the exercise README for the exact commands and expected results. If
something is broken, inspect it before asking for help:

```bash
kubectl describe <resource> <name>
kubectl get events --sort-by=.lastTimestamp
```

Clean up an exercise by deleting its namespace:

```bash
kubectl delete namespace ex1
```

Repeat with `ex2`, `ex3`, and so on for the later exercises.

## Working rules

- Keep all Kubernetes YAML, scripts, application source, and Helm charts in
  git.
- After Exercise 1, write manifests and use `kubectl apply -f`; do not use
  imperative resource creation commands such as `kubectl run`,
  `kubectl create deployment`, or `kubectl expose`.
- Use one branch per exercise and open a pull request against `main` when it
  is complete.
- Use small commits with meaningful messages.
- Commit every manifest before applying it to the cluster.
- Keep `NOTES.md` updated as you work.
- Never commit real credentials, kubeconfig files, certificates, keys, or
  Secret manifests containing sensitive values. Use example templates with
  placeholder values instead.

## Exercise order

1. Pods and `kubectl` basics
2. Deployments and rolling updates
3. Configuration and Secrets
4. Stateful workloads
5. Day-2 operations and Helm