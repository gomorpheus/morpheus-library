#!/bin/bash -eu
. /tmp/os_detect.sh

echo "os release: $OS_RELEASE - kube version: $KUBE_VERSION"

case "$OS_RELEASE" in
 ubuntu)
  case "$KUBE_VERSION" in
    *)
#prep
sudo swapoff -a ; sudo sed -i '/ swap / s/^/#/' /etc/fstab
#containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
#stuff
sudo modprobe overlay
sudo modprobe br_netfilter
#sysctl params
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
#sysctl apply
sudo sysctl --system
#install containerd
sudo apt-get update && sudo apt-get install -y containerd
#configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
# set runc cgroup driver to systemd
sed -i '86i\          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]' /etc/containerd/config.toml
sed -i '87i\            SystemdCgroup = true' /etc/containerd/config.toml
#restart containerd
sudo systemctl restart containerd
# kubeadm, kubelet
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=$KUBE_VERSION kubeadm=$KUBE_VERSION kubectl=$KUBE_VERSION
sudo apt-mark hold kubelet kubeadm kubectl
#cgroup driver
sudo sed -i 's/cgroupDriver: .*/cgroupDriver: systemd/' /var/lib/kubelet/config.yaml
#restart
sudo systemctl daemon-reload
sudo systemctl restart kubelet
#end
    ;;
  esac
  ;;
 centos|rhel|ol)
 	case "$KUBE_VERSION" in
    *)
      
    ;;
  esac
  ;;
 *)
  ;;
esac
