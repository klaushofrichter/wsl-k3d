#!/bin/bash
set -e

source ./config.sh
export NAMESPACE="grafana-cloud"

#
# Require KUBECONFIG
[ -z "${KUBECONFIG}" ] && echo "$0: KUBECONFIG not set. Exit." && exit 1

#
# Delete deployment if it exists
./grafana-cloud-undeploy.sh -f ${CONFIG}

echo
echo "==== $0: Generating the Grafana Cloud Dashboard"
sed -i 's/myapp/${APP}/g' grafana-cloud-dashboard.json.template 
cat grafana-cloud-dashboard.json.template | envsubst "${ENVSUBSTVAR}" > grafana-cloud-dashboard.json
echo "Dashboard ./grafana-cloud-dashboard.json is ready for upload to Grafana Cloud."

#
# Create namespace for grafana cloud if it does not exist
if [ -z $(kubectl get namespace | grep "^${NAMESPACE}" | cut -d " " -f 1 ) ]; then
  echo
  echo "==== $0: Create namespace \"${NAMESPACE}\""
  kubectl create namespace ${NAMESPACE}
fi 

echo
echo "==== $0: Installing grafana-cloud agent into namespace \"${NAMESPACE}\""
MANIFEST_URL=https://raw.githubusercontent.com/grafana/agent/main/production/kubernetes/agent-bare.yaml
curl -fsSL https://raw.githubusercontent.com/grafana/agent/release/production/kubernetes/install-bare.sh > /tmp/grafana-cloud-install.sh
/bin/sh -c "$(cat /tmp/grafana-cloud-install.sh)" > /tmp/grafana-cloud-install.yaml
kubectl create -f /tmp/grafana-cloud-install.yaml -n ${NAMESPACE} || true
cat grafana-cloud.yaml.template | envsubst  > /tmp/grafana-cloud-config.yaml  # artifact for debug
cat grafana-cloud.yaml.template | envsubst | kubectl apply -n ${NAMESPACE} -f - 

echo 
echo "==== $0: Waiting for Grafana Cloud Agent to be deployed"
kubectl rollout restart deployment/grafana-agent -n ${NAMESPACE}
kubectl rollout status deployment.apps grafana-agent -n ${NAMESPACE} --request-timeout 5m

