#!/usr/bin/env bash
set -euo pipefail

# ====== CONFIG ======
PROJECT_ID="nodejspython"
ZONE="us-central1-c"
CLUSTER_NAME="demo-cluster"
DOCKERHUB_USERNAME="pratha97"

RED="$(tput setaf 1)"; GRN="$(tput setaf 2)"; YLW="$(tput setaf 3)"; RS="$(tput sgr0)"

echo "${YLW}Using project:${RS} $PROJECT_ID ${YLW}zone:${RS} $ZONE ${YLW}cluster:${RS} $CLUSTER_NAME"

echo "${GRN}⟹ Getting GKE credentials...${RS}"
gcloud container clusters get-credentials "$CLUSTER_NAME" --zone "$ZONE" --project "$PROJECT_ID"

# ---- K8s: app namespace + services/deployments ----
echo "${GRN}⟹ Creating namespace and deploying apps...${RS}"
kubectl apply -f k8s/namespace.yaml

# Render manifests with your Docker Hub username
WORKDIR=$(mktemp -d)
for f in k8s/python-deployment.yaml k8s/node-deployment-blue.yaml k8s/node-deployment-green.yaml; do
  sed "s/DOCKERHUB_USERNAME/${DOCKERHUB_USERNAME}/g" "$f" > "$WORKDIR/$(basename "$f")"
done
cp k8s/python-service.yaml k8s/node-service.yaml k8s/node-color-services.yaml "$WORKDIR/"

kubectl -n app apply -f "$WORKDIR/python-deployment.yaml"
kubectl -n app apply -f "$WORKDIR/python-service.yaml"
kubectl -n app apply -f "$WORKDIR/node-deployment-blue.yaml"
kubectl -n app apply -f "$WORKDIR/node-deployment-green.yaml"
kubectl -n app apply -f "$WORKDIR/node-color-services.yaml"
kubectl -n app apply -f "$WORKDIR/node-service.yaml"

echo "${GRN}⟹ Waiting for pods...${RS}"
kubectl -n app rollout status deployment/python-app --timeout=180s || true
kubectl -n app rollout status deployment/node-app-blue --timeout=180s || true
kubectl -n app rollout status deployment/node-app-green --timeout=180s || true

# ---- Jenkins via Helm ----
echo "${GRN}⟹ Installing Jenkins (Helm)...${RS}"
if ! command -v helm >/dev/null 2>&1; then
  echo "${YLW}Helm not found. Installing (Linux x86_64) ...${RS}"
  curl -sSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add jenkins https://charts.jenkins.io
helm repo update
helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins --create-namespace \
  -f jenkins/values.yaml

# Allow Jenkins SA cluster-admin
kubectl apply -f jenkins/clusterrolebinding.yaml

echo "${GRN}⟹ Done!${RS}"
echo "${YLW}Node app external IP (once allocated):${RS} kubectl -n app get svc node-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo"
echo "${YLW}Open Jenkins (external IP):${RS} kubectl -n jenkins get svc jenkins -o jsonpath='{.status.loadBalancer.ingress[0].ip}' && echo"
echo "${YLW}Jenkins login:${RS} user=admin pass=admin123 (demo — change it)"
