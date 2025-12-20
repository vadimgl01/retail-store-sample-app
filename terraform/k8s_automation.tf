###################################################
# 1. Identity (ServiceAccount)
###################################################
resource "kubernetes_service_account_v1" "ecr_robot_sa" {
  metadata { 
    name      = "${var.project_name}-ecr-robot-sa" 
    namespace = "default"
  }
}

###################################################
# 2. Permissions (Role)
###################################################
resource "kubernetes_role_v1" "ecr_robot_role" {
  metadata { 
    name      = "${var.project_name}-ecr-robot-role" 
    namespace = "default"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "delete", "patch"]
  }
}

###################################################
# 3. The Glue (RoleBinding)
###################################################
resource "kubernetes_role_binding_v1" "ecr_robot_rb" {
  metadata { 
    name      = "${var.project_name}-ecr-robot-rb" 
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.ecr_robot_role.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.ecr_robot_sa.metadata[0].name
    namespace = "default"
  }
}

###################################################
# 4. The Robot (CronJob)
###################################################
resource "kubernetes_cron_job_v1" "ecr_refresher" {
  metadata {
    name      = "${var.project_name}-ecr-refresher"
    namespace = "default"
  }
  spec {
    schedule = "0 */8 * * *"
    job_template {
      metadata {} # <--- ADD THIS LINE (Fixes Error 1)
      spec {
        template {
          metadata {} # <--- ADD THIS LINE (Fixes Error 2)
          spec {
            service_account_name = kubernetes_service_account_v1.ecr_robot_sa.metadata[0].name
            container {
              name  = "ecr-token-refresher"
              image = "odaniait/aws-kubectl:latest"
              command = [
                "/bin/sh",
                "-c",
                <<-EOT
                TOKEN=$(aws ecr get-login-password --region ${var.region})
                kubectl delete secret regcred --ignore-not-found
                kubectl create secret docker-registry regcred \
                  --docker-server=${var.aws_account_id}.dkr.ecr.${var.region}.amazonaws.com \
                  --docker-username=AWS \
                  --docker-password=$TOKEN
                EOT
              ]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
