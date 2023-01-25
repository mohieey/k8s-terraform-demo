provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

variable username {
  type        = string
}

variable password {
  type        = string
}


resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_deployment" "mongo-depl" {
  depends_on = [kubernetes_persistent_volume_claim.mongo-pvc]

  metadata {
    name = "mongo-depl"
    labels = {
      app = "mongo-depl"
    }
    namespace = kubernetes_namespace.demo.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mongo-pod"
      }
    }

    template {
      metadata {
        labels = {
          app = "mongo-pod"
        }
      }

      spec {
        container {
          image = "mongo"
          name  = "mongo-container"
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value = kubernetes_secret.mongo-auth.data.username
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value = kubernetes_secret.mongo-auth.data.password
          }
          volume_mount {
            mount_path = "/data/db"
            name = "mongo-pvc" 
          }
        }
        volume{
            name = "mongo-pvc"
            persistent_volume_claim {
                claim_name = "mongo-pvc"
            }
        }
      }

    }
  }
}

resource "kubernetes_deployment" "express-depl" {
  depends_on = [kubernetes_deployment.mongo-depl]
  
  metadata {
    name = "express-depl"
    labels = {
      app = "express-depl"
    }
    namespace = kubernetes_namespace.demo.id
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "express-pod"
      }
    }

    template {
      metadata {
        labels = {
          app = "express-pod"
        }
      }

      spec {
        container {
          image = "mohiey/ex-demo:13"
          name  = "express-container"
          env {
            name = "USERNAME"
            value = kubernetes_secret.mongo-auth.data.username
          }
          env {
            name = "PASSWORD"
            value = kubernetes_secret.mongo-auth.data.password
          }
        }
      }

    }
  }
}

resource "kubernetes_service" "express-srv" {
  metadata {
    name = "express-srv"
    namespace = kubernetes_namespace.demo.id
  }
  spec {
    selector = {
      app = kubernetes_deployment.express-depl.spec[0].selector[0].match_labels.app
    }
    port {
      port        = 3000
      target_port = 3000
      node_port = 30005
    }

    type = "NodePort"
  }
}

resource "kubernetes_service" "mongo-srv" {
  metadata {
    name = "mongosrv"
    namespace = kubernetes_namespace.demo.id
  }
  spec {
    selector = {
      app = kubernetes_deployment.mongo-depl.spec[0].selector[0].match_labels.app
    }
    port {
      port        = 27017
      target_port = 27017
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_persistent_volume" "mongo-pv" {
  metadata {
    name = "mongo-pv"
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      local {
        path = "/home/docker"
      }
    }
    node_affinity {
        required {
            node_selector_term {
                match_expressions {
                    key = "kubernetes.io/hostname"
                    operator = "Exists"
                }
            }
        }
    }
    storage_class_name = "gggg"
  }

}

resource "kubernetes_persistent_volume_claim" "mongo-pvc" {
  metadata {
    name = "mongo-pvc"
    namespace = kubernetes_namespace.demo.id
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = "gggg"
    volume_name = "${kubernetes_persistent_volume.mongo-pv.metadata.0.name}"
  }
}

resource "kubernetes_secret" "mongo-auth" {
  metadata {
    name = "mongo-auth"
    namespace = kubernetes_namespace.demo.id
  }

  data = {
    username = var.username
    password = var.password
  }

}
