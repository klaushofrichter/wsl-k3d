#!/bin/bash
set -e

source ./config.sh

[ -z "$1" ] && echo "need one argument to scale. Exit." && exit 1
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

kubectl scale --replicas=$1 deployment ${APP}-deploy -n ${APP}
kubectl rollout status deployment.apps ${APP}-deploy -n ${APP} --request-timeout 5m
