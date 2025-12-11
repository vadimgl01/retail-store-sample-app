#!/bin/bash -xe

echo "==== CONTROL-PLANE START (v1.34.2) ===="

# BUCKET variable is assumed to be exported by the Terraform user_data environment.

#############################################
# 0. Wait for Kubernetes Binaries (CRITICAL FIX FOR RACE CONDITION)
#############################################
echo "--- Waiting for Kubeadm binary to be available in PATH ---"
MAX_RETRIES=15
RETRY_INTERVAL=10
RETRY_COUNT=0

while ! command -v kubeadm &> /dev/null; do
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "ERROR: kubeadm binary not found after $MAX_RETRIES attempts. Exiting."
        exit 1
    fi
    echo "Kubeadm not yet available. Retrying in ${RETRY_INTERVAL} seconds (Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)..."
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep ${RETRY_INTERVAL}
    hash -r
done

echo "Kubeadm binary found. Proceeding with init."


#############################################
# 1. kubeadm init
#############################################
echo "--- Retrieving private IP from the default network interface ---"
# CRITICAL FIX: Targets the 'src' field of the routing table output to get the local private IP.
MASTER_IP=$(ip route get 1 | grep -oP 'src \K[\d.]+')
echo "Identified Master IP: ${MASTER_IP}"

echo "--- Initializing Kubeadm cluster ---"
# Note: Removed --node-name flag to avoid hostname mismatch warnings/errors
sudo kubeadm init \
    --pod-network-cidr=192.168.0.0/16 \
    --apiserver-advertise-address=${MASTER_IP} \
    --upload-certs
export KUBECONFIG=/etc/kubernetes/admin.conf
#############################################
# 1.5 Kubelet Restart Fix (CRITICAL FINAL STEP)
#############################################
echo "--- Applying Kubelet restart fix to ensure API Server starts ---"
# This resolves the timing issue where the Kubelet fails to start immediately after init.
sudo systemctl daemon-reload
sudo systemctl restart kubelet
sudo systemctl status kubelet --no-pager || true


#############################################
# 2. Configure kubeconfig (FINAL HARDENED FIX)
#############################################
echo "--- Configuring kubectl for all users ---"

# 2a. Configure for the user running this script ($HOME - usually root if run by cloud-init)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 2b. Configure for the default non-root user (e.g., 'ubuntu' or 'ec2-user')
DEFAULT_USER=$(ls /home | head -n 1) 
if [ -n "$DEFAULT_USER" ]; then
    echo "Configuring kubectl for user: $DEFAULT_USER"
    
    # CRITICAL FIX: Ensure the .kube directory is created and has correct ownership 
    sudo mkdir -p /home/$DEFAULT_USER/.kube
    
    # Copy the configuration file
    sudo cp /etc/kubernetes/admin.conf /home/$DEFAULT_USER/.kube/config
    
    # Use chown -R to recursively fix permissions on the directory and file (SOLVES localhost:8080)
    sudo chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER/.kube
fi

#############################################
# 3. Wait for API Server
#############################################
echo "--- Waiting for core API Server components to be ready ---"
# This ensures the API server is functional before applying CNI.
kubectl wait --for=condition=ready pod -l component=kube-apiserver --timeout=5m -n kube-system

#############################################
# 4. Install Calico CNI
#############################################
echo "--- Installing Calico CNI ---"
# Calico version v3.26.1 is compatible with Kubernetes v1.34
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

#############################################
# 5. Create join script and upload to S3
#############################################
echo "--- Uploading join script to S3 ---"
JOIN_CMD=$(sudo kubeadm token create --print-join-command 2>/dev/null)

cat <<EOF > /tmp/join.sh
#!/bin/bash -xe
# This script joins a worker node to the Kubernetes cluster
sudo ${JOIN_CMD}
EOF

sudo chmod +x /tmp/join.sh
aws s3 cp /tmp/join.sh s3://${BUCKET}/join.sh

echo "Control plane initialized and join.sh uploaded."
echo "==== CONTROL-PLANE COMPLETE ===="
