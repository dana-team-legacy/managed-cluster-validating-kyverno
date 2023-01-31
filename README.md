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

## Build for OpenShift
The only supported way to install Kyverno in Production is using `helm`. However, at times it's more preferable to create an `all-in-one.yaml` that can be installed using `kubectl`.

A `Makfile` takes care of all the things necessary in order to install Kyverno on OpenShift and in an offline environment.

In order to create a single YAML containing the latest `Kyverno` manifests, use the `make build` directive of the `Makefile`.

```
make build
```

The output is a `manifests/kyverno.yaml` file which can be used to deploy `Kyverno` on an OpenShift cluster and can be used in Production, as per the `Kyverno` [installation page](https://kyverno.io/docs/installation/). including the changes needed to enable the `Node` [policy](https://kyverno.io/policies/other/protect_node_taints/protect-node-taints/).

## Offline Installation
`Kyverno` does not have built-in support for installation in an offline environment, but a `Makefile` entry takes care of it so there's a way to make the process easier.

The `offline-bundle.sh` script can be used to create a package usable for offline installation of the operator. 

The process is heavily inspired by [Offline Installation of Dell CSI Storage Providers](https://github.com/dell/dell-csi-operator/blob/main/scripts/csi-offline-bundle.md).

### Workflow
To perform an offline installation, the following steps should be performed:
1. Build an offline bundle.
2. Unpacking the offline bundle created in Step 1 and preparing for installation.
3. Perform an installation using the files obtained after unpacking in Step 2.

*NOTE: It is recommended to use the same build tool for packing and unpacking of images (either `docker` or `podman`).*

### Building an offline bundle
This needs to be performed on a Linux system with access to the internet as a git repo will need to be cloned, and container images pulled from public registries.

To build an offline bundle, the following steps are needed:

1. Perform a `git clone` of the desired repository:
    ```
    git clone https://github.com/dana-team/managed-cluster-validating-kyverno.git
    ```

2. Use the `Makefile` entry in order to create an offline bundle:
    ```
    make build-offline
    ```

The will perform the following steps:

- Determine required images by parsing the manifests.
- Perform an image pull of each image required.
- Save all required images to a file by running `docker save` or `podman save`.
- Build a `tar.gz` file containing the images as well as files required to install the operator.


### Unpacking the offline bundle and preparing for installation
This needs to be performed on a Linux system with access to an image registry that will host container images. If the registry requires login, that should be done before proceeding.

To prepare for installation, the following steps need to be performed:

1. Copy the offline bundle file created from the previous step to a system with access to an image registry available to your OpenShift cluster.

2. Expand the bundle file by running: 
    ```
    tar xvfz <filename>
    ```

3. Run the `offline-bundle.sh` script and supply the `-p` option as well as the path to the internal registry with the `-r` option:
    ```
    make unpack-offline INTERNAL-REGISTRY=<path to internal registry>
    ```

The script will then perform the following steps:

- Load the required container images into the local system
- Tag the images according to the user-supplied registry information
- Push the newly tagged images to the registry
- Modify the manifests to refer to the newly tagged/pushed images

### Install
Run installation of the `all-in-one.yaml` in your favorite way. For example:

```
kubectl create -f manifests/kyverno.yaml
```

*Note: You may need to use `kubectl create` instead of `kubectl apply`.*