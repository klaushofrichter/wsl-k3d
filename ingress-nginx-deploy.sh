#!/bin/bash
# this installs ingress-nginx
set -e
source ./config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

#
# remove existing deployment
./ingress-nginx-undeploy.sh

echo
echo "==== $0: Running helm for ingress-nginx, chart version ${INGRESSNGINXCHART}"
helm install -f ingress-nginx-values.yaml ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace --version ${INGRESSNGINXCHART}

echo 
echo "==== $0: Wait for rollout completing"
kubectl rollout status deployment.apps ingress-nginx-controller -n ingress-nginx --request-timeout 5m
kubectl rollout status daemonset.apps svclb-ingress-nginx-controller -n ingress-nginx --request-timeout 5m
x="0"
echo -n "Waiting for ingress-nginx-controller to get an IP address.."
while [ true ]; do
  LBIP=$(kubectl get svc ingress-nginx-controller --template="{{range .status.loadBalancer.ingress}}{{.ip}} {{end}}" -n ingress-nginx)
  [ ! -z "${LBIP}" ] && echo " IP number is ${LBIP}" && break
  echo -n "."
  x=$(( ${x} + 2 ))
  [ ${x} -gt "100" ] && echo "ingress-nginx-controller not ready after ${x} seconds. Exit." && exit 1
  sleep 2
done

