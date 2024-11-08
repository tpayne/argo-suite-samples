#!/bin/sh

command=$(basename $0)
direct=$(dirname $0)
trap 'stty echo; echo "${command} aborted"; exit' 1 2 3 15
#
CWD=$(pwd)

platform=

group="argodemo"
name="${group}001"

location=
region=
aksloc="ukwest"
gcploc="us-east1-c"

remove=0
getIp=0
tmpFile="/tmp/tmpFile$$.tmp"
logFile="/tmp/addonngix$$.tmp"
authIps=
context="${name}"

rmFile() {
	if [ -f "$1" ]; then
		(rm -f "$1") >/dev/null 2>&1
	fi
	return 0
}

#
# Usage
#
usage() {
	#

	while [ $# -ne 0 ]; do
		case $1 in
		-g | --group | -p | --project)
			group=$2
			shift 2
			;;
		-l | --location | -z | --zone)
			location=$2
			shift 2
			;;
		-c | --context)
			context=$2
			shift 2
			;;
		-n | --name)
			name=$2
			shift 2
			;;
		-r | --region)
			region=$2
			shift 2
			;;
		-d | --delete)
			remove=1
			shift
			;;
		--authIps)
			authIps=$2
			shift 2
			;;
		-t | --target-platform)
			platform=$2
			shift 2
			;;
		--debug)
			set -xv
			shift
			;;
		-?*)
			show_usage
			break
			;;
		--)
			shift
			break
			;;
		- | *) break ;;
		esac
	done

	if [ "x${platform}" = "x" ]; then
		echo "${command}: Error: You must specify a platform - 'gcp' or 'azure'"
		show_usage
	fi
	if [ "x${platform}" != "xgcp" -a "x${platform}" != "xazure" ]; then
		echo "${command}: Error: You must specify a platform - 'gcp' or 'azure'"
		show_usage
	fi
	if [ "x${location}" = "x" ]; then
		if [ "x${platform}" = "xgcp" ]; then
			location="${gcploc}"
		else
			location="${aksloc}"
		fi
	fi
	return 0
}

show_usage() {
	echo "${command}: Azure"
	echo "${command}: -t azure -g <groupName> -l <location>"
	echo "${command}: where <groupName> is the resource group to use"
	echo "${command}:       <location> is the location to use"
	echo "${command}: GCP"
	echo "${command}: -t gcp -p <projectName> -z <zone>"
	echo "${command}: where <projectName> is the project to use"
	echo "${command}:       <zone> is the zone to use"
	exit 0
}

# Azure routines...
cleanUpAzure() {
	echo "${command}: Cleaning up the controller resource group..."
	(az group show -n $1) >/dev/null 2>&1
	if [ $? -gt 0 ]; then
		return 0
	fi

	(az group delete -n $1 -y && az group delete -n NetworkWatcherRG -y) >/dev/null 2>&1
	return $?
}

installAzure() {
	rmFile "${tmpFile}"
	echo "${command}: Deploying the controller \"${1}\" in \"${2}\"..."
	echo "${command}: - create resource group..."
	(az group create --name $1 --location $2) >/dev/null 2>&1
	if [ $? -gt 0 ]; then
		return 1
	fi

	# dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
	exIpAddr="$(dig +short myip.opendns.com @resolver1.opendns.com)"
	ipAddr="$(ipconfig getifaddr en0)"
	echo "${command}: - create K8s system scoped to ${exIpAddr}..."

	extIp="${exIpAddr}/32"

	if [ "x${authIps}" != "x" ]; then
		extIp="${exIpAddr}/32,${authIps}"
	else
		extIp="${exIpAddr}/32"
	fi

	(az aks create -n "${name}" -g $1 --network-plugin azure \
		--enable-managed-identity \
		--enable-oidc-issuer --enable-workload-identity \
		--enable-addons http_application_routing \
		--generate-ssh-keys --location $2 \
		--api-server-authorized-ip-ranges "${extIp}") >${tmpFile} 2>&1
	if [ $? -gt 0 ]; then
		cat "${tmpFile}"
		rmFile "${tmpFile}"
		return 1
	fi

	cat "${tmpFile}" > "${logFile}"

	echo "${command}: - enable K8s system ${name} ${group}..."
	(az aks get-credentials -n "${name}" -g $1 --overwrite-existing --context "${context}") >${tmpFile} 2>&1
	if [ $? -gt 0 ]; then
		cat "${tmpFile}"
		rmFile "${tmpFile}"
		return 1
	fi
	cat "${tmpFile}" >> "${logFile}"
	return 0
}

# GCP routines...
cleanUpGCP() {
	rmFile "${tmpFile}"
	echo "${command}: Cleaning up the cluster..."
	(gcloud services enable container.googleapis.com && \
	 gcloud config set project "${1}" && \
	 gcloud container clusters delete "${name}" --zone "${2}" --quiet) \
	 	> "${tmpFile}" 2>&1
	return $?
}

installGCP() {
k8sversion="1.27.2-gke.1200"
	# dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com
	exIpAddr="$(dig +short myip.opendns.com @resolver1.opendns.com)"
	ipAddr="$(ipconfig getifaddr en0)"
	echo "${command}: - create K8s system scoped to ${exIpAddr}..."

	extIp="${exIpAddr}/32"

	if [ "x${authIps}" != "x" ]; then
		extIp="${exIpAddr}/32,${authIps}"
	else
		extIp="${exIpAddr}/32"
	fi

	rmFile "${tmpFile}"
	echo "${command}: Deploying the controller \"${name}\" in \"${1}\"..."
	(gcloud services enable container.googleapis.com && \
	 gcloud config set project "${1}" && \
	 gcloud container --project "${1}" \
		clusters create "${name}" \
		--zone "${2}" \
		--logging=SYSTEM,WORKLOAD \
		--monitoring=SYSTEM \
		--no-enable-basic-auth --cluster-version "${k8sversion}" \
		--release-channel "regular" \
		--machine-type "n1-standard-2" --image-type "UBUNTU_CONTAINERD" \
		--disk-type "pd-standard" --disk-size "100" \
		--metadata disable-legacy-endpoints=true \
		--scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
		--max-pods-per-node "20" --preemptible \
		--num-nodes "10" --enable-ip-alias \
		--network "projects/${1}/global/networks/default" \
		--subnetwork "projects/${1}/regions/${3}/subnetworks/default" \
		--no-enable-intra-node-visibility \
		--default-max-pods-per-node "110" \
		--enable-ip-alias \
		--no-enable-private-nodes \
        --enable-master-authorized-networks \
        --master-authorized-networks="${extIp}" \
		--addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
		--enable-autoupgrade \
		--enable-autorepair --max-surge-upgrade 1 \
		--max-unavailable-upgrade 0 --tags "gitops") >${tmpFile} 2>&1
	if [ $? -gt 0 ]; then
		cat "${tmpFile}"
		rmFile "${tmpFile}"
		return 1
	fi

	cat "${tmpFile}" > "${logFile}"

	echo "${command}: - enable K8s system ${1} ${2}..."
	(gcloud container clusters get-credentials "${name}" --zone "${2}" && \
	 gcloud projects add-iam-policy-binding "${1}" \
	 	--member=user:$(gcloud config get-value account) \
		--role=roles/container.admin) \
		>${tmpFile} 2>&1
	if [ $? -gt 0 ]; then
		cat "${tmpFile}"
		rmFile "${tmpFile}"
		return 1
	fi

	echo "${command}: - install Nginx controller..."

	(kubectl create namespace ingress-nginx) >/dev/null 2>&1
	if [ $? -gt 0 ]; then
		return 1
	fi

	# https://kubernetes.github.io/ingress-nginx/deploy/#gce-gke
	(kubectl create clusterrolebinding cluster-admin-binding \
		--clusterrole cluster-admin \
		--user $(gcloud config get-value account) && \
	 kubectl apply -f \
		https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml) \
		 >"${tmpFile}" 2>&1
	cat "${tmpFile}" >> "${logFile}"
	return 0
}

# Generic routines...
cleanUp() {
	if [ "x${platform}" = "xazure" ]; then
		cleanUpAzure $*
		return $?
	else
		cleanUpGCP $*
		return $?
	fi
	return 1
}

install() {
	rmFile "${tmpFile}"
	if [ "x${platform}" = "xazure" ]; then
		installAzure $*
		return $?
	else
		installGCP $*
		return $?
	fi
	return 1
}

usage $*

cleanUp ${group} ${location}
if [ $? -ne 0 -a $remove -gt 0 ]; then
	echo "${command}: - Error: The cleanup of the controller failed"
	exit 1
fi

if [ $remove -gt 0 ]; then
	exit 0
fi

install ${group} ${location} ${region}
if [ $? -ne 0 ]; then
	echo "${command}: - Error: The installation of the controller failed"
	exit 1
fi

echo "${command}: Log file is in ${logFile}"
exit 0
