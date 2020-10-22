module github.com/openfaas/faas-netes

go 1.15

require (
	github.com/google/go-cmp v0.5.2
	github.com/gorilla/mux v1.7.3
	github.com/openfaas/faas v0.0.0-20191125105239-365f459b3f3a
	github.com/openfaas/faas-provider v0.15.1
	github.com/pkg/errors v0.9.1
	github.com/prometheus/client_golang v1.8.0
	k8s.io/api v0.19.3
	k8s.io/apimachinery v0.19.3
	k8s.io/client-go v0.19.3
	k8s.io/code-generator v0.19.3
	k8s.io/klog/v2 v2.3.0
	sigs.k8s.io/controller-tools v0.4.0 // indirect
)
