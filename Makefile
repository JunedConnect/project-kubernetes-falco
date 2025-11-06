.PHONY: setup portforward upgrade-prometheus-stack upgrade-falco destroy

setup:
	@echo " Creating Kind cluster..."
	kind create cluster --config kind-conf.yaml --name juned-cluster
	
	@echo "\n Setting kubectl context to kind..."
	kubectl config use-context kind-juned-cluster
	
	@echo "\n Adding Helm repositories..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add falcosecurity https://falcosecurity.github.io/charts
	
	@echo "\n Installing Prometheus Stack..."
	helm install prom-graf prometheus-community/kube-prometheus-stack \
		--namespace monitor \
		--create-namespace \
		--values helm-values/prom-graf-values.yml
	
	@echo "\n Installing Falco..."
	helm install falco falcosecurity/falco \
		--namespace falco \
		--create-namespace \
		--values helm-values/falco-values.yml

	@echo "\n Event Generator..."
	helm install event-generator falcosecurity/event-generator \
		--namespace falco \
		--create-namespace \
		--values helm-values/event-generator-values.yml
	
	@echo "\n Setup complete! Your cluster is ready."
	@echo "To verify installations:"
	@echo "  kubectl get pods -n monitor"
	@echo "  kubectl get pods -n falco"

portforward:
	@echo "Waiting for pods to be ready..."
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=prom-graf -n monitor --timeout=180s
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitor --timeout=180s
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitor --timeout=180s
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n monitor --timeout=180s
	kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=falcosidekick,app.kubernetes.io/component=ui -n falco --timeout=180s
	
	@echo "Starting port-forwards..."
	@echo "Prometheus: http://localhost:9090"
	kubectl port-forward svc/prom-graf-kube-prometheus-prometheus -n monitor 9090:9090 &
	@echo "Grafana: http://localhost:8080"
	kubectl port-forward svc/prom-graf-grafana -n monitor 8080:80 &
	@echo "Alertmanager: http://localhost:9093"
	kubectl port-forward svc/prom-graf-kube-prometheus-alertmanager -n monitor 9093:9093 &
	@echo "Falco Sidekick: http://localhost:2802"
	kubectl port-forward svc/falco-falcosidekick-ui -n falco 2802:2802 &
	
	@echo "\n Port-forwards started! Press Ctrl+C to stop all port-forwards."
	wait


upgrade-prometheus-stack:
	@echo "\n Upgrading Prometheus Stack..."
	helm upgrade prom-graf prometheus-community/kube-prometheus-stack \
		--namespace monitor \
		--values helm-values/prom-graf-values.yml

upgrade-falco:	
	@echo "\n Upgrading Falco..."
	helm upgrade falco falcosecurity/falco \
		--namespace falco \
		--values helm-values/falco-values.yml

	@echo "\n Upgrading Event Generator..."
	helm upgrade event-generator falcosecurity/event-generator \
		--namespace falco \
		--values helm-values/event-generator-values.yml
	
	@echo "\n All upgrades complete!"

destroy:
	@echo "Cleaning up Helm releases..."
	helm uninstall falco -n falco || true
	helm uninstall prom-graf -n monitor || true
	
	@echo "\n Destroying Kind cluster..."
	kind delete cluster --name juned-cluster

	@echo "\n Cleanup complete! Everything has been removed."
