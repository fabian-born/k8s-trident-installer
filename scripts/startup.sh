#!/usr/bin/env bash

KUBECONFIG_FILE=/config
DEBUG=1
K8S_TRIDENT_NS=trident
KUBECTL=kubectl

_STARTDIR=$(pwd)
TRIDENT_DOWNLOAD_URL=https://github.com/NetApp/trident/releases/download/v20.04.0/trident-installer-20.04.0.tar.gz
TRIDENT_DOWNLOAD_FOLDER=download-tmp
### functions
function writelog(){
	if [[ $DEBUG = "1" ]]
	then
	   echo [$(date '+%Y-%m-%d %H:%M:%S')] $1
	fi
}
###

if [ -f "$KUBECONFIG_FILE" ]; then
	export KUBECONFIG=$KUBECONFIG_FILE
	writelog "KUBECONFIG found in $KUBECONFIG_FILE"
else 
	writelog "Use default path for KUBECONFIG"
        unset KUBECONFIG
fi
kubectl cluster-info

writelog "Check Kubernetes Cluster Information"
d=($(kubectl get nodes 2>/dev/null | wc))
_KC=`echo ${d[0]}`

if [[ $_KC == "0"  ]]
then
	writelog "	- No Connection to k8s cluster - ${_KC}"
	exit -1
else
	writelog "	- Cluster Connection found - ${_KC}"
	writelog "`kubectl cluster-info`"
fi

writelog "Check Namespace..."
ns=`kubectl get namespace $K8S_TRIDENT_NS --no-headers --output=go-template={{.metadata.name}} 2>/dev/null`
if [ -z "${ns}" ]; then
  writelog  "	Namespace $K8S_TRIDENT_NS not found, create it new!"
  $KUBECTL create namespace $K8S_TRIDENT_NS 2> /dev/null
else
  writelog "   Namespace $K8S_TRIDENT_NS found"	
fi


writelog "Download Trident..."

mkdir $_STARTDIR/$TRIDENT_DOWNLOAD_FOLDER
cd $_STARTDIR/$TRIDENT_DOWNLOAD_FOLDER
wget $TRIDENT_DOWNLOAD_URL
writelog "`tar xfvz trident-installer-20.04.0.tar.gz`"
cd trident-installer

_K8SVERSION=$(($KUBECTL version --client=false --short=true | grep Server) | awk -F '[:=]'  '{print $2}') 
_K8SVERSION="${_K8SVERSION//v}"
_K8SVERSION="${_K8SVERSION//.}"
writelog "$_K8SVERSION"


if [[ $_K8SVERSION < "1160"  ]]
then
	writelog " Prepare Trident Installation pre K8S Version 1.6"
	writelog " `$KUBECTL create -f deploy/crds/trident.netapp.io_tridentprovisioners_crd_pre1.16.yaml`"
else
        writelog " Prepare Trident Installation post K8S Version 1.6"
	writelog " `$KUBECTL create -f deploy/crds/trident.netapp.io_tridentprovisioners_crd_post1.16.yaml`"
fi

writelog " `$KUBECTL create -f deploy/bundle.yaml`"

writelog "Checking trident-operator state ..."
until [ $($KUBECTL get deployment -n trident trident-operator --no-headers |  awk -F ' '  '{print $2}') == "1/1" ] 
do
	sleep 5
	writelog "."
done

writelog "`$KUBECTL get deployment -n $K8S_TRIDENT_NS trident-operator --no-headers`"

until [ $($KUBECTL get pods -n trident --no-headers | grep trident-operator |  awk -F ' '  '{print $2}') == "1/1" ]
do
        sleep 5
        writelog "."
done
writelog "`$KUBECTL get pods -n $K8S_TRIDENT_NS --no-headers | grep trident-operator`"

writelog "`$KUBECTL create -f deploy/crds/tridentprovisioner_cr.yaml`"

sleep 10
writelog "Check tprov state"
writelog "`$KUBECTL get tprov -n trident --no-headers`"

until [ $($KUBECTL describe tprov trident -n trident | grep "Status:  " | awk -F ':  '  '{print $2}') == "Installed" ]
do
        sleep 5
        writelog "."
done
writelog "`$KUBECTL describe tprov trident -n trident`"


writelog " Installation finished!"
writelog " Clean up all folder...."
cd $_STARTDIR
rm -rf $_STARTDIR/$TRIDENT_DOWNLOAD_FOLDER/
