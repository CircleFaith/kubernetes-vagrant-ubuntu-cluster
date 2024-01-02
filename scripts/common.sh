#!/bin/bash

sudo apt-get update

sudo ufw disable

# Disable swap
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab


# 持久化加载overlay, br_netfilter模块，解决k8s网络问题
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# 加载模块 (必须) 使得流量可以穿透防火墙
sudo modprobe overlay
sudo modprobe br_netfilter
sudo modprobe -- ip_vs
sudo modprobe -- ip_vs_sh
sudo modprobe -- ip_vs_rr
sudo modprobe -- ip_vs_wrr
sudo modprobe -- nf_conntrack

# kubernetes 网络相关配置
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl -p /etc/sysctl.conf && sudo sysctl --system

# 安装containerd
echo "Installing containerd..."
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd && sudo containerd config default |sudo tee /etc/containerd/config.toml
sudo sed -i 's#SystemdCgroup = false#SystemdCgroup = true#' /etc/containerd/config.toml
sudo grep SystemdCgroup /etc/containerd/config.toml

sudo sed -i 's#registry.k8s.io/pause:3.6#registry.aliyuncs.com/google_containers/pause:3.9#' /etc/containerd/config.toml
sudo grep sandbox_image /etc/containerd/config.toml

sudo systemctl restart containerd && sudo systemctl enable containerd && sudo systemctl status containerd
echo "containerd installed"

# 安装apt-transport-https
sudo apt-get install -y apt-transport-https curl

# 添加kubernetes仓库
echo "Adding kubernetes repository..."
sudo curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg |sudo apt-key add -
sudo add-apt-repository "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main"

# sudo echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

# sudo cat <<EOF |sudo tee /etc/apt/sources.list.d/kubernetes.list
# deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
# deb-src https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
# EOF
echo "kubernetes repository added"

# 安装kubelet, kubeadm, kubectl,并将其设为hold状态
echo "Installing kubelet, kubeadm, kubectl..."
sudo apt-get update && sudo apt-get install -y kubelet=1.28.2-00 kubeadm=1.28.2-00 kubectl=1.28.2-00
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl daemon-reload && sudo systemctl restart kubelet && sudo systemctl enable kubelet
echo "kubelet installed"