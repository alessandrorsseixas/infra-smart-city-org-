.PHONY: help ansible run-scripts start-minikube delete-minikube enable-ingress check-rancher logs

help:
	@echo "Available targets:"
	@echo "  make ansible          # Run Ansible playbook (will prompt for sudo)"
	@echo "  make run-scripts      # Run the old shell orchestrator scripts (scripts/dev/run.sh)"
	@echo "  make start-minikube   # Start minikube with docker driver"
	@echo "  make delete-minikube  # Delete minikube cluster"
	@echo "  make enable-ingress   # Enable minikube ingress addon"
	@echo "  make check-rancher    # Show Rancher ingress, services and pods"
	@echo "  make logs             # Tail Rancher pods logs"

ansible:
	cd Ansible && ansible-playbook playbooks/site.yml -K

run-scripts:
	bash scripts/dev/run.sh rancher.local

start-minikube:
	minikube start --driver=docker --memory=4096 --cpus=2 --kubernetes-version=v1.31.0

delete-minikube:
	minikube delete --all

enable-ingress:
	minikube addons enable ingress || true
	kubectl wait --namespace ingress-nginx --for=condition=Ready pod --selector=app.kubernetes.io/component=controller --timeout=300s || true

check-rancher:
	@echo "Minikube IP: $(shell minikube ip 2>/dev/null || echo unknown)"
	kubectl get pods -n cattle-system || true
	kubectl get svc -n cattle-system || true
	kubectl get ingress -n cattle-system || true

logs:
	kubectl logs -n cattle-system -l app=rancher --tail=200 -f || true
