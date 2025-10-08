# Ansible provisioning for Minikube + Rancher

This repository contains an Ansible playbook to provision a local Minikube cluster and install Rancher for development/testing.

Quick start (run as normal user):

```bash
cd Ansible
ansible-playbook playbooks/site.yml -K
```

Roles created:
- prereqs: install Docker, kubectl, minikube, helm
- minikube: start minikube and validate with a test pod
- ingress: enable minikube ingress addon
- cert: install cert-manager
- rancher: install Rancher via Helm and add /etc/hosts entry

Notes:
- Some tasks call `minikube`, `kubectl`, and `helm` so ensure these are available in PATH.
- Ansible will use `become` when writing to `/etc/hosts` or installing system packages.
- The current roles are a scaffold mapped from existing shell scripts; you can extend each role with handlers, templates and variables.
