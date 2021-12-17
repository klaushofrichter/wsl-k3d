#!/bin/bash
# this installs fluentbit
set -e
source ./config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

#
# remove exiting installation
./fluentbit-undeploy.sh

echo
echo "==== $0: Deploy fluentbit with metrics exporter, chart version ${FLUENTBITCHART}"
kubectl create namespace fluentbit
kubectl create configmap etcmachineidcm -n fluentbit --from-file=/etc/machine-id
cat fluentbit-values.yaml.template | envsubst | helm install -f - fluentbit fluent/fluent-bit --version ${FLUENTBITCHART} -n fluentbit

echo
echo "==== $0: Wait for fluentbit to finish deployment"
kubectl rollout status daemonset.apps fluentbit-fluent-bit -n fluentbit --request-timeout 5m

