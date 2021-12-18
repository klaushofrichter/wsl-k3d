#!/bin/bash
# This builds an image and updates the image of the pod in the running cluster.
# A rolling update is then performed without service interruption.

set -e
source ./config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

echo
echo "==== $0: Build app image ${APP}:${VERSION}"
npm install
docker build -t ${APP}:${VERSION} .

echo
echo "==== $0: Import new image ${APP}:${VERSION} to k3d ${CLUSTER} (this may take a while)"
k3d image import ${APP}:${VERSION} -c ${CLUSTER} --keep-tools

echo
echo "==== $0: Update application image and restart"
kubectl set image deployment.apps/${APP}-deploy ${APP}-container=${APP}:${VERSION} -n ${APP}
kubectl rollout restart deployment.apps/${APP}-deploy -n ${APP} --request-timeout 5m
kubectl annotate deployment.apps/${APP}-deploy kubernetes.io/change-cause="image update via $0" -n ${APP}

echo
echo "==== $0: Wait for ${APP} update deployment to finish"
kubectl rollout status deployment.apps ${APP}-deploy -n ${APP} --request-timeout 5m

