#!/bin/bash
set -e
source config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

echo
echo "==== $0: installing CRDs for Prometheus Operator ${PROMOPERATOR}"
BASE="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v${PROMOPERATOR}/example/prometheus-operator-crd"

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^alertmanagerconfigs.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_alertmanagerconfigs.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_alertmanagerconfigs.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^alertmanagers.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_alertmanagers.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_alertmanagers.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^podmonitors.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_podmonitors.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_podmonitors.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^probes.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_probes.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_probes.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^prometheuses.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_prometheuses.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_prometheuses.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^prometheusrules.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_prometheusrules.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_prometheusrules.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^servicemonitors.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_servicemonitors.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_servicemonitors.yaml
fi

if [[ -z $(kubectl get CustomResourceDefinition | \
  grep '^thanosrulers.monitoring.coreos.com' | cut -d " " -f 1 ) ]]; then 
  kubectl create -f ${BASE}/monitoring.coreos.com_thanosrulers.yaml
else
  kubectl replace -f ${BASE}/monitoring.coreos.com_thanosrulers.yaml
fi

