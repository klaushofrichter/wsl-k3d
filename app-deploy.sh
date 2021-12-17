#!/bin/bash
# this installs the app
set -e
source ./config.sh
[ -z "${KUBECONFIG}" ] && echo "KUBECONFIG not defined. Exit." && exit 1

echo
echo "==== $0: Build app image ${APP}:${VERSION}"
npm install
chmod a+rx node_modules/node-jq/bin/jq  # odd
docker build -t ${APP}:${VERSION} .

echo
echo "==== $0: Import new image ${APP}:${VERSION} to k3d ${CLUSTER} (this may take a while)"
k3d image import ${APP}:${VERSION} -c ${CLUSTER} --keep-tools

#
# remove existing deployment
./app-undeploy.sh

echo
echo "==== $0: Deploy application (namespace, pods, service, ingress)"
cat app.yaml.template | envsubst "${ENVSUBSTVAR}" | kubectl create -f - --save-config

echo
echo "==== $0: Wait for ${app} deployment to finish"
kubectl rollout status deployment.apps ${APP}-deploy -n ${APP} --request-timeout 5m

