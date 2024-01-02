#! /bin/bash

# 指定k8s版本
K8S_VERSION=v1.28.2
# 指定主控节点ip
MASTER_IP="192.168.56.30"
# 指定主控节点主机名
MASTER_HOSTNAME=$(hostname -s)
# 指定当前 K8s 集群中 Service 所使用的 CIDR
SERVICE_CIDR="10.96.0.0/12"
# 指定当前 K8s 集群中 Pod 所使用的 CIDR
POD_CIDR="10.244.0.0/16"
IMAGE_REPOSITORY=registry.aliyuncs.com/google_containers

sudo kubeadm init \
    --kubernetes-version=${K8S_VERSION} \
    --pod-network-cidr=${POD_CIDR} \
    --service-cidr=${SERVICE_CIDR} \
    --image-repository=${IMAGE_REPOSITORY} \
    --ignore-preflight-errors=Swap \
    --apiserver-advertise-address=${MASTER_IP} \
    --node-name=${MASTER_HOSTNAME}

sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

config_path="/vagrant/configs"

if [ -d $config_path ]; then
sudo rm -f $config_path/*
else
sudo mkdir -p $config_path
fi

sudo cp -i /etc/kubernetes/admin.conf $config_path/config
sudo kubeadm token create --print-join-command > /vagrant/scripts/join.sh
sudo chmod +x /vagrant/scripts/join.sh

sudo kubectl apply -f /vagrant/scripts/kube-flannel.yml