# This resource requires the 'kubernetes' provider to be configured
resource "kubernetes_storage_class_v1" "ebs_gp2_default" {
  metadata {
    name = "${var.project_prefix}-gp2"
    annotations = {
      # This is the annotation that makes it the default StorageClass
      "storageclass.kubernetes.io/is-default-class" = "true" 
    }
  }
  
  # The provisioner for the AWS EBS CSI driver
  storage_provisioner = "ebs.csi.aws.com" 

  # The parameters passed to the AWS EBS CSI driver
  parameters = {
    type = "gp2" # General Purpose SSD
  }
  
  # When the PVC is deleted, the underlying EBS volume should also be deleted
  reclaim_policy = "Delete" 
  
  # Wait for a pod to start consuming the PVC before provisioning the volume (best practice)
  volume_binding_mode = "WaitForFirstConsumer"
}
