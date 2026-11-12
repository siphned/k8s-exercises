# YAML files
- take care to indent everything properly, otherwise stuff breaks easily
- indentation is two spaces wide(!)

# `kubectl`
- as a CLI it is supposedly the most in control you can be while talking to the API, the downside is you have to learn it
- Pods are somewhat immutable, so to add another container (1.3), we have to create a new one (delete and recreate)

# Answers to questions in exercise
- Q: "Note:  localhost  works across containers — why?"
  A: The containers are running inside the same Pod, so they share the same Pod IP; which in turn means they also share the same `lo`, `localhost`, network ports