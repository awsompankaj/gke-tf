resource "helm_release" "nginxingress" {
  name       = "nginx-ingress"
  namespace  = "ingress-nginx"
  create_namespace = "true"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  depends_on = [
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary
  ]
}

resource "helm_release" "argocd" {
  depends_on = [
    helm_release.nginxingress,
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary
        ]
  name       = "argocd"
  namespace  = "argocd"
  create_namespace = true
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "nginx"
  }
  set {
    name  = "server.ingress.tls[0].secretName"
    value = "argotls"
  }
  set {
    name  = "server.ingress.https"
    value = "true"
  }
  set {
    name  = "server.ingress.hosts[0]"
    value = "argo.k8s.mevijay.dev"
  }
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
  set {
    name  = "configs.secret.extra.dex\\.github\\.clientSecret"
    value = "dsfsdfdsfsdfsfsfsdfsdf"
  }
}

resource "helm_release" "k8s_dashboard" {
  name       = "kubernetes-dashboard"
  namespace  = "kubernetes-dashboard"
  create_namespace = true
  repository = "https://kubernetes.github.io/dashboard"
  chart      = "kubernetes-dashboard"
  depends_on = [
    helm_release.nginxingress,
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary
        ]
  set {
    name  = "ingress.enabled"
    value = "true"
  }
    set {
    name  = "ingress.hosts[0]"
    value = "dashboard.k8s.mevijay.dev"
  }
    set {
    name  = "ingress.tls[0].secretName"
    value = "dashboard-tls"
  }
    set {
      name = "ingress.annotations\\.nginx\\.ingress\\.kubernetes\\.io/secure-backends"
      value = "true"
    }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary
        ]
  name       = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.3.1"
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "k8sPolicyCRDs" {
  name       = "kyverno-crds"
  namespace  = "kyverno"
  create_namespace = true
  depends_on = [
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary
  ]
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno-crds"
}

resource "helm_release" "k8sPolicy" {
  name       = "kyverno"
  namespace  = "kyverno"
  depends_on = [
    google_container_node_pool.primary_nodes,
    google_container_cluster.primary,
    helm_release.k8sPolicyCRDs
  ]
  repository = "https://kyverno.github.io/kyverno"
  chart      = "kyverno"
}
