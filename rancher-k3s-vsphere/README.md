# Rancher K3s vSphere Cluster Template

Helm chart template for creating **Rancher v2.13.2** managed **K3s** clusters on **VMware vSphere**. The chart renders a `provisioning.cattle.io/v1` Cluster and two `VsphereMachineConfig` resources (control and worker pools) that match the configuration typically set in the Rancher UI.

## Requirements

- Rancher v2.13.x (management cluster)
- vSphere cloud credential created in Rancher (Cluster Management → Cloud Credentials)
- VM template in vSphere for “Deploy from template: Data Center”
- `kubectl` context pointing at the **Rancher management cluster** when applying

## Cluster name (required)

You must provide a **cluster name** when installing or templating. The chart will fail with a clear error if `clusterName` is missing.

```bash
# Example: install with cluster name
helm install my-k3s . --set clusterName=my-k3s-cluster
```

## Quick start

1. **Set required values**
   - `clusterName` – name of the cluster in Rancher (e.g. `my-k3s-cluster`).
   - `cloudCredentialSecretName` – reference to your vSphere cloud credential (e.g. `cattle-global-data:cc-xxxxx`).
   - `vsphere.template` – full path to the VM template in vSphere (e.g. `/CDS-Datacenter(GDL2)/vm/CVS-olab-01/ubuntu-template`).

2. **Template and apply** (recommended for review first):

   ```bash
   helm template my-release . \
     --set clusterName=my-k3s-cluster \
     --set cloudCredentialSecretName=cattle-global-data:cc-xxxxx \
     --set vsphere.template="/CDS-Datacenter(GDL2)/vm/CVS-olab-01/your-template" \
     > manifests.yaml
   kubectl apply -f manifests.yaml
   ```

3. **Or install directly** (if your kubeconfig is the Rancher management cluster):

   ```bash
   helm install my-release . -n fleet-default --create-namespace \
     --set clusterName=my-k3s-cluster \
     --set cloudCredentialSecretName=cattle-global-data:cc-xxxxx \
     --set vsphere.template="/CDS-Datacenter(GDL2)/vm/CVS-olab-01/your-template"
   ```

4. Open **Rancher UI** → **Cluster Management** and confirm the new cluster appears and provisions.

## Default configuration (from your UI values)

| Item | Default |
|------|--------|
| **Kubernetes version** | v1.34.2+k3s1 |
| **Cluster label** | `provider: cks` |
| **Control pool** | name: `control`, 3 nodes, etcd + Control Plane |
| **Worker pool** | name: `worker`, 3 nodes, worker |
| **vSphere** | Datacenter, Resource Pool, Datastore, Folder, Host, Network as in values.yaml |
| **VM sizing** | 8 CPU, 16384 MiB memory, 20000 MB disk |
| **Cloud config** | salt-minion enable/start (customize in `values.yaml`) |

## Main values

| Value | Description | Required |
|-------|-------------|----------|
| `clusterName` | Name of the cluster in Rancher | **Yes** (e.g. `--set clusterName=my-cluster`) |
| `cloudCredentialSecretName` | Cloud credential secret (e.g. `cattle-global-data:cc-xxxxx`) | **Yes** |
| `vsphere.template` | Full path to VM template in vSphere | **Yes** |
| `kubernetesVersion` | K3s version (default: `v1.34.2+k3s1`) | No |
| `labels` | Cluster labels (default includes `provider: cks`) | No |
| `controlPool.machineCount` | Number of control/etcd nodes (default: 3) | No |
| `workerPool.machineCount` | Number of worker nodes (default: 3) | No |
| `vsphere.*` | Datacenter, pool, datastore, folder, host, networks, CPU, memory, disk, cloudConfig, etc. | Override as needed |

## File layout

```
rancher-k3s-vsphere/
├── Chart.yaml
├── values.yaml
├── README.md
└── templates/
    ├── cluster.yaml                      # provisioning.cattle.io/v1 Cluster
    ├── vsphere-machine-config-control.yaml
    ├── vsphere-machine-config-worker.yaml
    └── NOTES.txt
```

## Customization

- **Cloud config**: Edit `values.yaml` → `vsphere.cloudConfig` (YAML under `runcmd`, etc.).
- **Pools**: Change `controlPool` / `workerPool` (name, machineCount, roles) in `values.yaml`.
- **vSphere**: Adjust `vsphere` (datacenter, resourcePool, datastore, folder, host, networks, cpuCount, memorySize, diskSize) in `values.yaml` or via `--set`.

## Troubleshooting: "no matches for kind ... in version rke-machine-config.cattle.io/v1"

If Helm fails with **resource mapping not found** or **no matches for kind "VsphereMachineConfig"** (or similar), the machine config CRD kind in your Rancher cluster may differ.

1. **Discover the correct kind** on your Rancher management cluster:
   ```bash
   kubectl get crd | grep rke-machine
   ```
   Look for a vSphere-related CRD (e.g. `vmwarevsphereconfigs.rke-machine-config.cattle.io`). The **kind** is the singular CamelCase form (e.g. `VmwarevsphereConfig`).

2. **Override in the chart**:
   ```bash
   helm install my-release . --set clusterName=my-k3s \
     --set machineConfigKind=VmwarevsphereConfig
   ```
   Or set `machineConfigKind` and optionally `machineConfigApiVersion` in `values.yaml`.

3. Default is `VmwarevsphereConfig` (Rancher often uses `<Provider>Config` like `Amazonec2Config`). If your Rancher uses `VsphereMachineConfig`, set `machineConfigKind: VsphereMachineConfig`.

## Notes

- Resources are created in the **fleet-default** namespace by default (`fleetNamespace`).
- Machine config names are `{clusterName}-control-config` and `{clusterName}-worker-config`.
- Ensure the VM template exists at `vsphere.template` and supports cloud-init if you use cloud config.
