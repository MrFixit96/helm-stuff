#!/bin/bash
if [[ -z $1 ]];then
    NAMESPACE="$1"
  else
    NAMESPACE="default"
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CONFIG="configmap,serviceaccount,secret"
DEPLOY="deployment,pod,replicaset,service,statefulset"
DEPLOY="clusterrole,clusterrolebinding"
OBJECTS="${CONFIG?},${DEPLOY?}"

kubectl delete ${OBJECTS?} --selector=app=vault-agent-demo --namespace=${NAMESPACE}
kubectl delete mutatingwebhookconfigurations vault-agent-injector-cfg
kubectl delete clusterrole vault-agent-injector-clusterrole 
kubectl delete clusterrolebinding vault-agent-injector-binding vault-server-binding

helm delete vault -n ${NAMESPACE}
helm delete tls-test -n ${NAMESPACE}
kubectl delete pvc --all -n
kubectl delete namespace vault
