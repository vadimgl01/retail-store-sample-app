#!/bin/bash -xe

echo "==== KUBE-COMMON START ===="

#############################################
# 1. Disable swap
#############################################
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

#############################################
# 2. Kernel modules & sysctl 
#############################################
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
lsmod | grep br_netfilter
lsmod | grep overlay

#############################################
# 2.5 Install Required Network Utilities
#############################################
echo "--- Installing required system utilities: conntrack and socat ---"
sudo apt-get update
sudo apt-get install -y conntrack socat

#############################################
# 3. Install containerd (v1.7.14)
#############################################
echo "--- Installing containerd ---"

curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mkdir -p /usr/local/lib/systemd/system/
sudo mv containerd.service /usr/local/lib/systemd/system/
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

systemctl status containerd --no-pager || true

#############################################
# 4. Install runc (v1.1.12)
#############################################
echo "--- Installing runc ---"
cd /tmp
# CRITICAL FIX: Direct install via pipe to ensure binary integrity
sudo curl -sL https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64 \
  | sudo install /dev/stdin -m 755 /usr/local/sbin/runc

#############################################
# 5. Install CNI plugins (v1.5.0)
#############################################
echo "--- Installing CNI plugins ---"
cd /tmp
curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz

#############################################
# 6. Install kubeadm, kubelet, kubectl (FIXED DIRECT INSTALL)
#############################################
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
sudo systemctl enable --now kubelet

kubeadm version
kubelet --version
kubectl version --client
#############################################
# 7. Configure crictl (FIXED PATH)
#############################################
echo "--- Configuring crictl ---"
# We now know the binary is valid, so this should work.
sudo /usr/local/bin/crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock || true

echo "==== KUBE-COMMON COMPLETE ===="
