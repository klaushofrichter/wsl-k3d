#!/bin/bash
# this installs kube-prometheus-stack
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

set -e
source ./config.sh
[[ -z "${KUBECONFIG}" ]] && echo "KUBECONFIG not defined. Exit." && exit 1

#
# remove exiting prometheus installation
./prom-undeploy.sh

echo
echo "==== $0: Install prometheus-community stack, chart ${KUBEPROMETHEUSSTACKCHART} (this may show warnings related to beta APIs)"
export SLACK_OR_NULL="null"
if [ ${SLACK_ENABLE} == "yes" ]; then
  SLACK_RECEIVER_CONFIG="am-values-slack.yaml.template"
  export SLACK_OR_NULL="slack"
fi
cat prom-values.yaml.template am-values.yaml.template ${SLACK_RECEIVER_CONFIG} | envsubst "${ENVSUBSTVAR}" | helm install --values - prom \
  prometheus-community/kube-prometheus-stack --version ${KUBEPROMETHEUSSTACKCHART} -n monitoring --create-namespace

echo
echo "==== $0: installing custom dashboard"
mkdir -p dashboards 
sed -i 's/myapp/${APP}/g' app-dashboard.json.template # not really needed
cat app-dashboard.json.template | envsubst "${ENVSUBSTVAR}" > dashboards/app-dashboard.json
kubectl create configmap ${APP}-dashboard-configmap -n monitoring --from-file="dashboards/app-dashboard.json"
kubectl patch configmap ${APP}-dashboard-configmap -n monitoring -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}'

echo
echo "==== $0: installing ingress-nginx dashboards with some customization"
if [ ! -f dashboards/ingress-nginx-dashboard.json ]; then
  wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/nginx.json -O dashboards/ingress-nginx-dashboard.json
  sed -i 's/NGINX Ingress controller/Ingress NGINX controller/g' dashboards/ingress-nginx-dashboard.json
fi
kubectl create configmap ingress-nginx-dashboard -n monitoring --from-file="dashboards/ingress-nginx-dashboard.json"
kubectl patch configmap ingress-nginx-dashboard -n monitoring -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}'
if [ ! -f dashboards/request-handling-performance.json ]; then
  wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/grafana/dashboards/request-handling-performance.json -O dashboards/request-handling-performance.json
  sed -i 's/Request Handling Performance/Ingress NGINX: Request Handling Performance/g' dashboards/request-handling-performance.json
fi
kubectl create configmap ingress-nginx-perf-dashboard -n monitoring --from-file="dashboards/request-handling-performance.json"
kubectl patch configmap ingress-nginx-perf-dashboard -n monitoring -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}'

echo
echo "==== $0: installing fluentbit dashboard with some customization"
if [ ! -f dashboards/fluentbit-dashboard.json ]; then
  wget https://raw.githubusercontent.com/fluent/fluent-bit-docs/8172a24d278539a1420036a9434e9f56d987a040/monitoring/dashboard.json -O dashboards/fluentbit-dashboard.json
  sed -i 's/${DS_PROMETHEUS}/Prometheus/g' dashboards/fluentbit-dashboard.json
  sed -i 's/DS_PROMETHEUS/Prometheus/g' dashboards/fluentbit-dashboard.json
  sed -i 's/^  "tags": \[\],/  "tags": \["logging", "fluent-bit"\],/g' dashboards/fluentbit-dashboard.json
fi
kubectl create configmap fluentbit-dashboard -n monitoring --from-file="dashboards/fluentbit-dashboard.json"
kubectl patch configmap fluentbit-dashboard -n monitoring -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}'

echo
echo "==== $0: installing influx-stats dashboard with some customization"
if [ ! -f dashboards/influxdb-stats-dashboard.json ]; then
  wget https://grafana.com/api/dashboards/5448/revisions/1/download -O dashboards/influxdb-stats-dashboard.json
  sed -i 's/${DS_PROMETHEUS}/Prometheus/g' dashboards/influxdb-stats-dashboard.json
  sed -i 's/DS_PROMETHEUS/Prometheus/g' dashboards/influxdb-stats-dashboard.json
  sed -i 's/^  "tags": \[\],/  "tags": \["logging", "influxdb"\],/g' dashboards/influxdb-stats-dashboard.json
  cat dashboards/influxdb-stats-dashboard.json | npx jq '.time = { "from": "now-60m", "to": "now" }' > /tmp/influxdb-stats-dashboard.json
  mv /tmp/influxdb-stats-dashboard.json dashboards/influxdb-stats-dashboard.json
fi
kubectl create configmap influxdb-dashboard -n monitoring --from-file="dashboards/influxdb-stats-dashboard.json"
kubectl patch configmap influxdb-dashboard -n monitoring -p '{"metadata":{"labels":{"grafana_dashboard":"1"}}}'

echo 
echo "==== $0: Remove dashboards that may not work in K3D"
kubectl delete configmap -n monitoring prom-kube-prometheus-stack-proxy || true
kubectl delete configmap -n monitoring prom-kube-prometheus-stack-persistentvolumesusage || true

echo 
echo "==== $0: Patch existing dashboards to use browser timezone"
MAPS=$(kubectl get configmaps -l grafana_dashboard=1 -n monitoring | tail -n +2 | awk '{print $1}')
for m in ${MAPS}
do
  echo -n "Processing map ${m}: "
  kubectl get configmap ${m} -n monitoring -o yaml | \
    sed 's/"timezone": ".*"/"timezone": "browser"/g' | \
    kubectl replace -f - -n monitoring
done

echo
echo "==== $0: Wait for everything to roll out"
kubectl rollout status deployment.apps prom-grafana -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-state-metrics -n monitoring --request-timeout 5m
kubectl rollout status deployment.apps prom-kube-prometheus-stack-operator -n monitoring --request-timeout 5m
kubectl rollout status statefulset.apps/alertmanager-prom-kube-prometheus-stack-alertmanager -n monitoring --request-timeout 5m
echo -n "Wait for prom-grafana ingress to be available.."
while [ "$(kubectl get ing prom-grafana -n monitoring -o json | npx jq -r .status.loadBalancer.ingress[0].ip)" = "null" ]
do
  i=$[$i+1]
  [ "$i" -gt "60" ] && echo "this took too long... exit." && exit 1
  echo -n "."
  sleep 2
done
sleep 1
echo
echo "done"

