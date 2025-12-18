############################################
# CONTROL PLANE NODE
############################################
resource "aws_instance" "control_plane" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.vadim_nodes.id]
  key_name               = var.ssh_key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<EOF
#!/bin/bash -xe

export BUCKET="${var.bootstrap_bucket}"

########################################
# 1) Install AWS CLI + basic tools (HARDENED)
########################################
sudo apt-get update -y
sudo apt-get install -y unzip curl

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# --- FIX: Explicitly set PATH for immediate use and pause ---
export PATH="/usr/local/bin:$PATH" 
sleep 5
# --- FIX END ---

aws --version || true

########################################
# 2) Download scripts from S3 (Using $$BUCKET fix)
########################################
aws s3 cp s3://${var.bootstrap_bucket}/kube-common.sh   /tmp/kube-common.sh
aws s3 cp s3://${var.bootstrap_bucket}/control-plane.sh /tmp/control-plane.sh
chmod +x /tmp/kube-common.sh
chmod +x /tmp/control-plane.sh

########################################
# 3) Run bootstrap (VARIABLE FIX)
########################################
# FIX: Export BUCKET variable for control-plane.sh to upload join script to S3
bash /tmp/kube-common.sh
bash /tmp/control-plane.sh

EOF

  tags = {
    Name = "${var.project_name}-control-plane"
    Role = "control-plane"
  }

  depends_on = [
    aws_iam_instance_profile.ec2_profile,
    aws_s3_object.kube_common,
    aws_s3_object.control_plane
  ]
}


############################################
# WORKER NODES
############################################
resource "aws_instance" "worker_nodes" {
  count                  = var.worker_count
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.vadim_nodes.id]
  key_name               = var.ssh_key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  user_data = <<EOF
#!/bin/bash -xe

export BUCKET="${var.bootstrap_bucket}"

########################################
# 1) Install AWS CLI + basic tools (HARDENED)
########################################
sudo apt-get update -y
sudo apt-get install -y unzip curl

cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# --- FIX: Explicitly set PATH for immediate use and pause ---
export PATH="/usr/local/bin:$PATH" 
sleep 5
# --- FIX END ---

aws --version || true

########################################
# 2) Download scripts from S3 
########################################
aws s3 cp s3://${var.bootstrap_bucket}/kube-common.sh /tmp/kube-common.sh
aws s3 cp s3://${var.bootstrap_bucket}/worker.sh      /tmp/worker.sh

chmod +x /tmp/kube-common.sh
chmod +x /tmp/worker.sh

########################################
# 3) Run bootstrap (VARIABLE FIX)
########################################
# FIX: Export BUCKET variable for worker.sh to download join script from S3
export BUCKET="${var.bootstrap_bucket}" 
bash /tmp/kube-common.sh
bash /tmp/worker.sh

EOF

  tags = {
    Name = "${var.project_name}-worker-${count.index + 1}"
    Role = "worker"
  }

  depends_on = [
    aws_iam_instance_profile.ec2_profile,
    aws_s3_object.kube_common,
    aws_s3_object.worker
  ]
}
