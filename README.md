# Technitium DNS Server Helm Chart 🌐

> ☸️ This Helm chart simplifies the deployment of **Technitium DNS Server** on Kubernetes. Technitium is an open-source authoritative as well as recursive DNS server that is designed to be self-hosted and privacy-focused.

## 🚀 Quick Start

To install the chart with the release name `technitium` from the Helm repository on GitHub Pages:

```bash
kubectl create namespace technitium

helm repo add technitium https://bugs5382.github.io/helm-technitium-chart
helm install technitium technitium/technitium \
  --set config.dnsDomain="dns-server" \
  --set persistence.storageClass="longhorn-static" \
  --namespace technitium
```

Or straight from the OCI registry on ghcr.io:

```bash
helm install technitium oci://ghcr.io/bugs5382/charts/technitium --version <version> \
  --set config.dnsDomain="dns-server" \
  --set persistence.storageClass="longhorn-static" \
  --namespace technitium
```

Each published release ships the same chart to both.

## ⚙️ Configuration

The following table lists the configurable parameters of the Technitium chart and their default values.

### Configuration Parameters

| Parameter | Description | Default | Required |
|:----------|:------------|:--------|:--------:|
| **Image Settings** | | | |
| image.repository | Container image repository. | `technitium/dns-server` | No |
| image.tag | Container image tag (falls back to the chart `appVersion`). | `.Chart.AppVersion` | No |
| image.pullPolicy | Kubernetes image pull policy. | `IfNotPresent` | No |
| **Core DNS Configuration** | | | |
| config.dnsDomain | Primary DNS domain the server identifies as. | `"dns-server"` | **YES** |
| config.adminPassword | Plain-text admin password (leave empty to auto-generate). | `""` | No |
| config.existingSecret | Use a pre-created administrator Secret and skip generating one. | `""` | No |
| config.passwordKey | Password key in `config.existingSecret`. | `password` | No |
| config.webServiceLocalAddresses | Comma-separated bind addresses for the web UI. | `""` | No |
| config.webServiceEnableHttps | Enables HTTPS for the management UI. | `false` | No |
| config.webServiceUseSelfSignedCert | Generates a self-signed cert for the UI when HTTPS is enabled. | `false` | No |
| config.webServiceTlsCertificatePath | Path to the `.pfx` certificate inside the container. | `/etc/dns/tls/cert.pfx` | No |
| config.webServiceTlsCertificatePassword | Password for the `.pfx` certificate. | `""` | No |
| config.webServiceHttpToTlsRedirect | Forces HTTP → HTTPS redirects for the UI. | `false` | No |
| config.optionalProtocolDnsOverHttp | Enables the DNS-over-HTTP helper protocol (port 8053). | `false` | No |
| config.recursionDeniedNetworks | Comma-separated CIDRs denied for recursion. | `""` | No |
| config.recursionAllowedNetworks | Comma-separated CIDRs allowed for recursion. | `""` | No |
| config.allowTxtBlockingReport | Respond with TXT records explaining blocked domains. | `false` | No |
| config.blockListUrls | Comma-separated block-list URLs. | `""` | No |
| config.preferIpv6 | Prefer IPv6 addresses when resolving names. | `""` | No |
| config.recursion | Recursion behavior: `Allow`, `Deny`, `AllowOnlyForPrivateNetworks`, `UseSpecifiedNetworks`. | `""` | No |
| config.recursionAcl | Comma-separated ACL rules controlling recursion. Example: `"allow 192.168.1.0/24, deny 0.0.0.0/0"`. | `""` | No |
| config.enableBlocking | Enables the domain blocking feature. | `""` | No |
| config.forwarders | Comma-separated upstream forwarder addresses. Example: `"1.1.1.1, 8.8.8.8"`. | `""` | No |
| config.forwarderProtocol | Protocol for upstream forwarders: `Udp`, `Tcp`, `Tls`, `Https`, `HttpsJson`. | `""` | No |
| config.logLocalTime | Log entries stamped with local server time instead of UTC. | `""` | No |
| **Ports & Services** | | | |
| ports.webHttp | HTTP port for the Web UI. | `5380` | No |
| ports.webHttps | HTTPS port for the Web UI. | `53443` | No |
| ports.doq.enabled | Enable DNS-over-QUIC (UDP/853). | `false` | No |
| ports.dot.enabled | Enable DNS-over-TLS (TCP/853). | `false` | No |
| ports.doh3.enabled | Enable DNS-over-HTTPS (UDP/443, HTTP/3). | `false` | No |
| ports.doh.enabled | Enable DNS-over-HTTPS (TCP/443, HTTP/1.1 or 2). | `false` | No |
| ports.dohHttpProxy.enabled | Enable DNS-over-HTTP proxy (TCP/80). | `false` | No |
| ports.dohProxy.enabled | Enable DNS-over-HTTP proxy (TCP/8053). | `false` | No |
| ports.dhcp.enabled | Enable DHCP server (UDP/67). | `false` | No |
| **Platform Services** | | | |
| serviceAccount.create | Create a dedicated ServiceAccount. | `true` | No |
| ingress.enabled | Toggle for the bundled ingress template. | `false` | No |
| ingress.className | IngressClass name (e.g. `"nginx"`, `"traefik"`). | `""` | No |
| ingress.annotations | Annotations to add to the ingress resource. | `{}` | No |
| service.labels | Extra labels on both Services (e.g. `lb-pool: aws` for a Cilium LB-IPAM `serviceSelector`). Chart-managed keys cannot be overridden. | `{}` | No |
| service.web.type | Service type for the web console Service. | `ClusterIP` | No |
| service.web.labels | Extra labels on the web Service only, merged over `service.labels`. | `{}` | No |
| service.web.annotations | Annotations on the web Service. | `{}` | No |
| service.dns.type | Service type for the DNS Service. | `LoadBalancer` | No |
| service.dns.labels | Extra labels on the DNS Service only, merged over `service.labels`. | `{}` | No |
| service.dns.annotations | Annotations on the DNS Service. | `{}` | No |
| service.dns.externalTrafficPolicy | Set to `Local` to preserve client source IPs. | `""` | No |
| **Workload** | | | |
| resources | Resource requests and limits for the container. | `{}` | No |
| securityContext | Security context for the container. | `{}` | No |
| **Persistence** | | | |
| persistence.enabled | Create/mount a PVC for `/etc/dns`. Set `false` to use an `emptyDir`: everything in `/etc/dns` is lost when the pod is replaced (see Running without persistence). | `true` | No |
| persistence.emptyDir.sizeLimit | Size limit for the `emptyDir` used when `persistence.enabled` is `false`. | unset | No |
| persistence.size | Size of the persistent volume claim. | `2Gi` | No |
| persistence.storageClass | StorageClass for the PVC (empty = cluster default). | `""` | No |
| persistence.accessModes | List of access modes for the PVC. | `[ReadWriteOnce]` | No |
| persistence.existingClaim | Use a pre-existing PVC instead of creating one (the chart then creates no PVC). | `""` | No |
| **Clustering** | | | |
| cluster.enabled | Participate in a Technitium cluster (see Clustering section below). | `false` | No |
| cluster.domain | Shared cluster zone name; must be identical on every node. | `""` | If `cluster.enabled` |
| cluster.primaryReleaseName | Helm release name of the primary node (set this on secondaries; empty on the primary). | `""` | No |
| cluster.primaryAdminSecretName | Primary administrator Secret used by a secondary's autoJoin Job. | Derived from primary release | No |
| cluster.primaryAdminPasswordKey | Key in the primary administrator Secret. | `password` | No |
| cluster.autoHttps | Force HTTPS + self-signed cert (required by DANE-EE node-to-node TLS). | `true` | No |
| cluster.autoJoin | Run a post-install Job that calls the cluster init/join API. | `true` | No |
| cluster.adminUsername | Admin username used by the join Job to authenticate. | `"admin"` | No |
| cluster.primaryNodeTotp | TOTP for the primary's admin user when 2FA is enabled. | `""` | No |
| cluster.jobImage.repository | Image used by the cluster-join Job (must include `curl`, non-root). | `curlimages/curl` | No |
| cluster.jobImage.tag | Tag for the join-Job image. | `"8.10.1"` | No |
| cluster.podNetworks | Pod CIDR(s) of the Kubernetes cluster, as a list or a comma-separated string. The primary sets them as Technitium's zone transfer and NOTIFY allowed networks. | `[]` | On the primary with `cluster.autoJoin` |
| cluster.frontService.enabled | On the primary, add a shared DNS Service in front of every node with the same `cluster.domain`. | `false` | No |
| cluster.frontService.type | Service type of the shared DNS Service. | `LoadBalancer` | No |
| cluster.frontService.labels | Extra labels on the shared DNS Service (merged over `service.labels`). | `{}` | No |
| cluster.frontService.annotations | Annotations on the shared DNS Service (e.g. an LB-IPAM IP). | `{}` | No |
| cluster.frontService.externalTrafficPolicy | Set to `Local` to preserve client source IPs. | `""` | No |
| **Zone Bootstrap** | | | |
| bootstrap.enabled | Create the listed zones on every pod start if they are missing. | `true` | No |
| bootstrap.zones | Forward zones: a name, or `{name, type}` (type defaults to `Primary`). | `[]` | No |
| bootstrap.reverseZones | Reverse zones: IPv4 CIDRs (expanded at the next octet boundary) or explicit `.arpa` names. | `[]` | No |
| bootstrap.image.repository | Image for the bootstrap sidecar (must include `curl`, non-root). | `curlimages/curl` | No |
| bootstrap.image.tag | Tag for the bootstrap sidecar image. | `"8.10.1"` | No |
| bootstrap.resources | Resources for the bootstrap sidecar. | 5m/8Mi requests, 100m/32Mi limits | No |

> **Note:** If `ports.dhcp.enabled` is set to `true`, the pod may require `hostNetwork: true` or specific CNI configurations to broadcast DHCP discovery packets correctly.

## 💾 Running without persistence

`persistence.enabled: false` is a supported mode, not only a test setting. When external-dns owns your records, it writes them back on its next sync, so the PVC is optional. The pod mounts an `emptyDir` at `/etc/dns`, and every time the pod is replaced Technitium starts as a blank server. The chart puts back what external-dns needs before it can write:

- **Admin login.** On a blank start Technitium sets the `admin` password from the chart's `<release>-technitium-admin` Secret. That Secret keeps its value across upgrades, so the same password works after every restart.
- **Zones.** The `bootstrap` sidecar creates every zone in `bootstrap.zones` and `bootstrap.reverseZones` that doesn't exist yet, then idles. It runs on every pod start, leaves existing zones alone, and logs each zone as created or already there (`kubectl logs <pod> -c bootstrap`). An API error exits non-zero, so the sidecar restarts and the failure shows up in the logs and the restart count.

Point the external-dns webhook at the admin password, not an API token. Tokens created in the web UI live in `/etc/dns` and are gone after a restart. Technitium's `DNS_SERVER_AUTH_STATIC_SESSIONS` is also skipped on a blank start: it only loads once an `auth.config` already exists.

```yaml
# Webhook sidecar env (external-dns-technitium-webhook)
- name: TECHNITIUM_USER
  value: admin
- name: TECHNITIUM_PASSWORD
  valueFrom:
    secretKeyRef:
      name: <release>-technitium-admin
      key: password
```

Example values for a home-lab network where external-dns manages `local.therabbithole.com` and PTR records for `10.110.0.0/19`:

```yaml
persistence:
  enabled: false
  emptyDir:
    sizeLimit: 64Mi

bootstrap:
  zones:
    - local.therabbithole.com
  reverseZones:
    - 10.110.0.0/19   # becomes 0.110.10.in-addr.arpa through 31.110.10.in-addr.arpa
```

What does **not** come back after a restart, because external-dns doesn't manage it:

- Zones and records created by hand, unless they are listed under `bootstrap`. Records in bootstrap zones return only when external-dns writes them.
- Settings changed in the web UI: forwarders, blocklists, recursion, logging, users, groups, API tokens and DNS apps. Set what the chart exposes through `config.*` (`forwarders`, `blockListUrls`, `recursion`, and so on); those are applied on every start.
- Query logs, dashboard stats and the cache.

**Clustering needs persistence.** A clustered node on an `emptyDir` comes back as a blank server that is no longer in the cluster, and the join Job only runs on `helm install`/`upgrade`. Keep `persistence.enabled: true` for every release in a cluster.

## 🔖 Versioning & Releases

The chart `appVersion` tracks the [Technitium DNS Server](https://github.com/TechnitiumSoftware/DnsServer) release it deploys, and the chart `version` follows semantic versioning for chart changes.

**Release cadence:** every upstream Technitium release gets a matching chart release. When Technitium publishes a new version, bump `appVersion` in `technitium/Chart.yaml` to it, bump the chart `version`, and publish a chart release so the Helm repository offers an installable version per upstream release. Chart-only changes (template fixes, new values) ship as their own chart `version` bump without an `appVersion` change.

## 🔐 Security & Admin Password

By default, this chart generates a random 16-character administrative password if `config.adminPassword` is left empty in your `values.yaml`. To use a Secret managed outside this Helm release:

```yaml
config:
  existingSecret: technitium-admin
  passwordKey: password
```

When configured, it takes precedence over `config.adminPassword`.

To retrieve your generated password after deployment, run:

```bash
kubectl get secret my-dns-admin -n technitium -o jsonpath="{.data.password}" | base64 --decode; echo
```

## 🧩 Clustering

Two (or more) Helm releases of this chart can join a single Technitium cluster — typically deployed side-by-side in the same namespace. Each release stays an independent Pod + PVC + Service; clustering simply lets them share settings, allow/block lists, DNS apps, users, permissions, and DNSSEC keys.

### How it works

- **Each release is a node.** Both releases live in the same namespace; resource names are prefixed with `{Release.Name}-technitium-…`, so there are no collisions.
- **Web service over HTTPS.** Technitium clustering uses DANE-EE for node-to-node TLS, so the web service must be HTTPS and TLS cannot be terminated by a reverse proxy. Setting `cluster.enabled=true` flips on HTTPS with a self-signed certificate automatically.
- **Each node is registered at its ClusterIP.** Technitium identifies cluster nodes by IP address. Its clustering guide says: "these IP addresses must be either static or care must be taken to ensure that they do not change later to avoid breaking the cluster unexpectedly." A pod IP changes on every restart, and a Service ClusterIP doesn't. So the chart registers each release's `<release>-technitium-web` ClusterIP, which also serves port 53 in cluster mode. A restarted node comes back at the same address with nothing to re-register.
- **The pod networks are allowed for zone transfer and NOTIFY.** Traffic that a node starts (AXFR/IXFR, NOTIFY) leaves from its pod IP, not the registered ClusterIP. Left alone, Technitium refuses it, and the secondary's cluster catalog zone never syncs. The primary therefore sets Technitium's cluster-wide `zoneTransferAllowedNetworks` and `notifyAllowedNetworks` to `cluster.podNetworks`, and Technitium copies both settings to every node. This is required on the primary; see [NetworkPolicy](#networkpolicy) for what it opens.
- **Automated init and join via Helm hook.** With `cluster.autoJoin=true` (default), a post-install/post-upgrade Job per release calls the Technitium HTTP API. On the primary it calls `/api/admin/cluster/init` and then applies the pod-network settings. On each secondary it calls `/api/admin/cluster/initJoin`. The Job finds ClusterIPs through cluster DNS and needs no Kubernetes API access. It is idempotent: on re-runs it checks `/api/admin/cluster/state`, re-applies the pod-network settings on the primary, and exits.
- **One address for clients (optional).** `cluster.frontService.enabled=true` on the primary adds `<release>-technitium-cluster-dns`, a LoadBalancer on port 53 that selects the pods of every release with the same `cluster.domain`. If one node is down, clients keep getting answers from the others, which hold the same zones.
- **Each node needs persistence.** A node's cluster membership lives in `/etc/dns`. On an `emptyDir` a replaced pod comes back as a blank server outside the cluster.

### Install order

The primary release **must** be installed first — secondaries' join Jobs read the primary's admin Secret via `secretKeyRef`. Installing a secondary first will leave its Job pod in `CreateContainerConfigError` until the primary's Secret exists. If the primary uses `config.existingSecret`, set the secondary's `cluster.primaryAdminSecretName` and `cluster.primaryAdminPasswordKey` to the primary Secret name/key.

### `dnsDomain` must align with `cluster.domain`

Technitium generates its self-signed HTTPS cert at first boot using `config.dnsDomain` as the certificate's Common Name. After clustering, peers fetch each other's cluster-state and connect to URLs like `https://<node>.<cluster.domain>:53443/`, and their heartbeats validate that exact name against the cert's CN. So every release in the cluster needs:

```yaml
config:
  dnsDomain: "<node-shortname>.<cluster.domain>"
cluster:
  domain: "<cluster.domain>"
  podNetworks:          # primary only
    - 10.244.0.0/16     # your cluster's pod CIDR
```

For example, with cluster domain `ns.example.local`, the primary uses `dnsDomain: tech-a.ns.example.local` and the secondary uses `dnsDomain: tech-b.ns.example.local`. Using a `dnsDomain` that isn't a subdomain of `cluster.domain` will produce `RemoteCertificateNameMismatch` heartbeat failures.

### Example: two-release cluster in `technitium-test`

The chart ships ready-to-use example values at `technitium/ci/cluster-primary.yaml` and `cluster-secondary.yaml`.

```bash
# 1. Primary
helm install tech-a ./technitium \
  --namespace technitium-test --create-namespace \
  --values ./technitium/ci/cluster-primary.yaml

# 2. Secondary (after the primary's Secret exists)
helm install tech-b ./technitium \
  --namespace technitium-test \
  --values ./technitium/ci/cluster-secondary.yaml

# 3. Watch the join Jobs
kubectl -n technitium-test get jobs -l technitium.io/cluster-domain=ns-example-local
kubectl -n technitium-test logs -l app.kubernetes.io/component=cluster-job --tail=200
```

After both Jobs report success, log into either web UI (`Administration → Cluster`) — both nodes should be listed, with one `Primary` and one `Secondary`.

### Disabling automation

If you'd rather initialize/join clustering by hand from the web UI, set `cluster.autoJoin=false` on both releases. The chart will still apply the discovery labels, enable HTTPS, and print join URLs + ClusterIP lookup commands in `NOTES.txt`. Register each node at its web ClusterIP, and on the primary add your pod CIDR under **Settings → Zone Transfer Allowed Networks** and **Notify Allowed Networks**. Without that step the catalog zone does not sync.

### Discovering cluster members

Every cluster resource carries the `technitium.io/cluster-domain` and `technitium.io/cluster-role` labels:

```bash
kubectl -n technitium-test get all -l technitium.io/cluster-domain=ns-example-local
```

### Limits

- DHCP service clustering is not supported by Technitium yet.
- Each release is a single-replica `Deployment` with its own PVC — scaling beyond 1 replica per release is out of scope; clustering across multiple releases is the supported topology.

### Failover

Every node answers DNS for the zones in the cluster catalog, so with `cluster.frontService` a node going down only removes one endpoint from the Service. Configuration changes, however, can only be made on the primary. Technitium has no automatic primary election; its guide describes "an option available to promote a secondary node to become a primary node in case when the primary node is offline and unrecoverable" (**Administration → Cluster** on the secondary). The chart does not automate promotion.

### NetworkPolicy

`cluster.podNetworks` lets any pod in those networks transfer every zone (AXFR) and send NOTIFY to every node without TSIG. On a shared cluster, restrict port 53 on the Technitium pods with a NetworkPolicy, so only the nodes themselves and your intended clients can reach it. For example, allow TCP/UDP 53 from pods labelled `technitium.io/cluster-domain=<domain>` and from your client namespaces. Keep the web ports (5380/53443) limited to the nodes and the namespaces that need the admin API, such as the external-dns webhook. A NetworkPolicy needs a CNI that enforces it (Cilium, Calico and others do).

### Background

Earlier chart versions registered the pod IP, which broke the cluster whenever a pod restarted. Earlier still, they registered the ClusterIP without allowing the pod networks, and catalog zone transfers were refused. [`docs/upstream-pr.md`](docs/upstream-pr.md) keeps the diagnosis trail.

## 🌐 Ingress

To enable the Web UI via an Ingress controller (like Traefik), update your `values.yaml`:

```yaml
ingress:
  enabled: true
  hosts:
    - host: dns.your-domain.com
      paths:
        - path: /
          pathType: Prefix
 ```

## 🤝 Acknowledgments

### The Technitium Team

A huge thank you to the [Technitium](https://technitium.com/) team for building such a robust, high-performance, and feature-rich open-source DNS server. This Helm chart is a community-driven project intended to make running their excellent software easier on Kubernetes.

### Personal Thanks

Building and maintaining open-source tools takes time and focus. I want to give a special thanks to **my wife, my daughter, and my son**. Your support and patience allow me the space to be a "geek" and contribute back to the community. You are my greatest motivation\!

## ⚖️ Disclaimers & Licensing

### Not an Official Product

**I am not the author of Technitium.** This repository contains only the **Helm Chart** used to deploy the software. I am not affiliated with Technitium Software in any official capacity. For issues related to the DNS server software itself, please refer to the [official Technitium GitHub repository](https://github.com/TechnitiumSoftware/DnsServer).

### No Liability

This Helm chart is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. **Use at your own risk.**

### License

This Helm chart is released under the [MIT License](https://opensource.org/licenses/MIT). Technitium DNS Server itself is released under its own respective license (GPLv3).
