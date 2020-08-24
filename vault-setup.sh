#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if  [[ -z $1 ]] && [[ $1 == "-h" ]];then
  echo -e "setup.sh usage: " \
           '$1 = kubernetes namespace' \
	   '$2 = my_public_cert_file.pem' \
           '$3 = my_public_cert_key_file.pem'
elif [[ -z $1 ]];then
  NAMESPACE="$1"
else
  NAMESPACE="default"
fi

if [[ -z $2 ]];then
  my_public_cert_file="$2"
fi

if [[ -z $3 ]];then
  my_public_cert_file="$3"
fi



${DIR?}/cleanup.sh

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
kubectl create namespace ${NAMESPACE}
helm install tls --namespace=${NAMESPACE?} ${DIR?}/tls

if [[ ! -f ${HOME?}/credentials.json ]]
then
	    echo "ERROR: ${HOME?}/credentials.json not found.  This is required to configure KMS auto-unseal."
	        exit 1
fi

kubectl create secret generic -n vault kms-creds \
	  --from-file=${HOME?}/credentials.json

kubectl -n vault create secret tls vault-public-crt --cert ${my_public_cert_file} --key ${my_public_cert_key_file}

helm install vault \
	  --namespace="${NAMESPACE?}" \
	    -f ${DIR?}/values.yaml hashicorp/vault --version=0.6.0

sleep 60
kubectl exec -ti vault-0 -n vault -- /bin/sh -c "export VAULT_CACERT=/vault/userconfig/tls-test-ca/ca.crt; vault operator init" |tee ~/.vault.info
kubectl exec -ti vault-1 -n vault -- /bin/sh -c "export VAULT_CACERT=/vault/userconfig/tls-test-ca/ca.crt; vault operator raft join -leader-ca-cert=@/vault/userconfig/tls-test-server/ca.crt https://vault-0.vault-internal:8200"
kubectl exec -ti vault-2 -n vault -- /bin/sh -c "export VAULT_CACERT=/vault/userconfig/tls-test-ca/ca.crt; vault operator raft join -leader-ca-cert=@/vault/userconfig/tls-test-server/ca.crt https://vault-0.vault-internal:8200"
