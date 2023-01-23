# Managed Cluster Validating Webhooks with Kyverno
This repository contains a number of `Kyervno` policies (`ClusterPolicy`) which are aimed to deny certain operations from a cutsomer in a Run Kubernrtes Service (`RKS`) solution. The policies are inspired heavily by  Red Hat's [managed-cluster-validating-webhooks](https://github.com/openshift/managed-cluster-validating-webhooks) repository, which conatins webhooks in Go for Red Hat's `ROSA` solution.

## Kyverno
Kyverno is a policy engine designed for Kubernetes. For information about how to write `Kyverno` policies, [follow the documentation on their website](https://kyverno.io/docs/).

## Included Policies
All the `Kyervno` policies are under the `policies/` directory in this repository. The policies reference ConfigMaps which include things like the managed namespaces and the privileged users; the ConfigMaps can be found in the `manifests/` directory.

The following table summarizes the policies that exist in this repository:

| Policy Name 	| Description 	|
|---	|---	|
| `deny-managed-namespaces` 	| Prevents access to RKS managed namespaces. Managed RKS customers may not modify namespaces specified in the `openshift-monitoring/namespaces` ConfigMap because customer workloads should be placed in customer-created namespaces. 	|
| `deny-rks-ownership` 	| Prevents access to RKS managed resources. A managed resource has a `"rks.dana.io/managed": "true"` label. 	|
| `deny-regular-users` 	| Prevents access to RKS managed resources. Managed RKS customers may not manage any objects in the following APIgroups [`autoscaling.openshift.io` `config.openshift.io` `operator.openshift.io` `network.openshift.io` `machine.openshift.io` `admissionregistration.k8s.io` `cloudcredential.openshift.io`], nor may Managed RKS customers alter the `APIServer`, `KubeAPIServer`, `OpenShiftAPIServer` or `ClusterVersion` objects. 	|
| `deny-configmaps` 	| Prevents modification of ConfigMaps that are called `user-ca-bundle` or that live in namespace `openshift-config`. 	|
| `deny-default-scc` 	| Prevents modification of default SCCs `anyuid`, `hostaccess`, `hostmount-anyuid`, `hostnetwork`, `hostnetwork-v2`, `node-exporter`, `nonroot`, `nonroot-v2`, `privileged`, `restricted`, `restricted-v2` 	|
| `deny-node-update` 	| Prevents modification of a node 	|
| `deny-prometheus-rule` 	| Prevents creation of a PrometheusRule in RKS managed namespaces 	|

## Build
In order to create a single YAML containing the latest `Kyverno` manifests, use the `make build` directive of the `Makefile`.

```
$ make build
```

The output is a `manifests/kyverno.yaml` file which can be used to deploy `Kyverno` on an OpenShift cluster and can be used in Production, as per the `Kyverno` [installation page](https://kyverno.io/docs/installation/). including the changes needed to enable the `Node` [policy](https://kyverno.io/policies/other/protect_node_taints/protect-node-taints/).