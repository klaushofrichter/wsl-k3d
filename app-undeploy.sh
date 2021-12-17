#!/bin/bash
# this uninstalls the app
set -e
source ./config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

#
# Delete app installation and namespace if namespace is present
if [[ ! -z $(kubectl get namespace | grep "^${APP}" ) ]]; then

  echo
  echo "==== $0: Delete application (namespace, pods, service, ingress)"
  cat app.yaml.template | envsubst "${ENVSUBSTVAR}" | kubectl delete -f - || true

else

  echo
  echo "==== $0: Namespace \"${APP}\" does not exist"
  echo "nothing to do."

fi

