# 🌐 Technitium DNS Server Helm Chart

This Helm chart simplifies the deployment of **Technitium DNS Server** on Kubernetes. Technitium is an open-source authoritative as well as recursive DNS server that is designed to be self-hosted and privacy-focused.

## 🚀 Quick Start

To install the chart with the release name `my-dns`:

```bash
kubectl create namespace technitium

helm install technitium technitium \
  --set config.dnsDomain="dns-server" \
  --set persistence.storageClass="longhorn-static" \
  --namespace technitium
```

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
| **Workload** | | | |
| resources | Resource requests and limits for the container. | `{}` | No |
| securityContext | Security context for the container. | `{}` | No |
| **Persistence** | | | |
| persistence.size | Size of the persistent volume claim. | `2Gi` | No |
| persistence.storageClass | StorageClass for the PVC (empty = cluster default). | `""` | No |
| persistence.accessModes | List of access modes for the PVC. | `[ReadWriteOnce]` | No |
| persistence.existingClaim | Use a pre-existing PVC instead of creating one. | `""` | No |
| **Clustering** | | | |
| cluster.enabled | Participate in a Technitium cluster (see Clustering section below). | `false` | No |
| cluster.domain | Shared cluster zone name; must be identical on every node. | `""` | If `cluster.enabled` |
| cluster.primaryReleaseName | Helm release name of the primary node (set this on secondaries; empty on the primary). | `""` | No |
| cluster.autoHttps | Force HTTPS + self-signed cert (required by DANE-EE node-to-node TLS). | `true` | No |
| cluster.autoJoin | Run a post-install Job that calls the cluster init/join API. | `true` | No |
| cluster.adminUsername | Admin username used by the join Job to authenticate. | `"admin"` | No |
| cluster.primaryNodeTotp | TOTP for the primary's admin user when 2FA is enabled. | `""` | No |
| cluster.jobImage.repository | Image used by the cluster-join Job (must include `curl`, non-root). | `curlimages/curl` | No |
| cluster.jobImage.tag | Tag for the join-Job image. | `"8.10.1"` | No |

> **Note:** If `ports.dhcp.enabled` is set to `true`, the pod may require `hostNetwork: true` or specific CNI configurations to broadcast DHCP discovery packets correctly.

## 🔖 Versioning & Releases

The chart `appVersion` tracks the [Technitium DNS Server](https://github.com/TechnitiumSoftware/DnsServer) release it deploys, and the chart `version` follows semantic versioning for chart changes.

**Release cadence:** every upstream Technitium release gets a matching chart release. When Technitium publishes a new version, bump `appVersion` in `technitium/Chart.yaml` to it, bump the chart `version`, and publish a chart release so the Helm repository offers an installable version per upstream release. Chart-only changes (template fixes, new values) ship as their own chart `version` bump without an `appVersion` change.

## 🔐 Security & Admin Password

By default, this chart generates a random 16-character administrative password if `config.adminPassword` is left empty in your `values.yaml`.

To retrieve your generated password after deployment, run:

```bash
kubectl get secret my-dns-admin -n technitium -o jsonpath="{.data.password}" | base64 --decode; echo
```

## 🧩 Clustering

Two (or more) Helm releases of this chart can join a single Technitium cluster — typically deployed side-by-side in the same namespace. Each release stays an independent Pod + PVC + Service; clustering simply lets them share settings, allow/block lists, DNS apps, users, permissions, and DNSSEC keys.

### How it works

- **Each release is a node.** Both releases live in the same namespace; resource names are prefixed with `{Release.Name}-technitium-…`, so there are no collisions.
- **Web service over HTTPS.** Technitium clustering uses DANE-EE for node-to-node TLS, so the web service must be HTTPS and TLS cannot be terminated by a reverse proxy. Setting `cluster.enabled=true` flips on HTTPS with a self-signed certificate automatically.
- **Stable peer IPs come from the ClusterIP Service.** The cluster zone holds A/TLSA records that point at each peer's ClusterIP — those IPs survive pod restarts. Pod IPs would not.
- **Automated join via Helm hook.** With `cluster.autoJoin=true` (default), a post-install Job per release calls the Technitium HTTP API: `/api/admin/cluster/init` on the primary, `/api/admin/cluster/initJoin` on each secondary. The Job is idempotent — on re-runs it checks `/api/admin/cluster/state` and exits cleanly if the node is already in the cluster.

### Install order

The primary release **must** be installed first — secondaries' join Jobs read the primary's admin Secret via `secretKeyRef`. Installing a secondary first will leave its Job pod in `CreateContainerConfigError` until the primary's Secret exists.

### `dnsDomain` must align with `cluster.domain`

Technitium generates its self-signed HTTPS cert at first boot using `config.dnsDomain` as the certificate's Common Name. After clustering, peers fetch each other's cluster-state and connect to URLs like `https://<node>.<cluster.domain>:53443/`, and their heartbeats validate that exact name against the cert's CN. So every release in the cluster needs:

```yaml
config:
  dnsDomain: "<node-shortname>.<cluster.domain>"
cluster:
  domain: "<cluster.domain>"
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

If you'd rather initialize/join clustering by hand from the web UI, set `cluster.autoJoin=false` on both releases. The chart will still apply the discovery labels, enable HTTPS, and print join URLs + ClusterIP lookup commands in `NOTES.txt`.

### Discovering cluster members

Every cluster resource carries the `technitium.io/cluster-domain` and `technitium.io/cluster-role` labels:

```bash
kubectl -n technitium-test get all -l technitium.io/cluster-domain=ns-example-local
```

### Limits

- DHCP service clustering is not supported by Technitium yet.
- Each release is a single-replica `Deployment` with its own PVC — scaling beyond 1 replica per release is out of scope; clustering across multiple releases is the supported topology.

### Known limitation: cluster config sync (catalog zone) fails on Kubernetes

Joining works (`cluster.autoJoin` Job calls `/api/admin/cluster/initJoin` successfully), but **ongoing config sync between nodes doesn't**, because of a fundamental impedance mismatch between Technitium's IP-based cluster identity and Kubernetes pod networking:

- At join time the chart registers each release's **web Service ClusterIP** with Technitium (since pod IPs are ephemeral).
- Technitium's primary catalog zone (`cluster-catalog.<cluster.domain>`) automatically restricts AXFR/IXFR to the IPs registered for each cluster member.
- But when a pod in Kubernetes initiates an outbound DNS zone transfer, the **source IP on the wire is the pod IP**, not the Service ClusterIP it ostensibly "owns". The two don't match, so the primary refuses the zone transfer:

  ```
  DNS Server refused a zone transfer request since the request IP address
  is not allowed by the zone: cluster-catalog.ns.example.local
  ```

- Without the catalog zone, the secondary never receives the TLSA records the primary publishes for each node. DANE-EE on the heartbeat path therefore has nothing to validate against and falls back to PKIX, which fails for the auto-generated self-signed cert with `UntrustedRoot`. From the secondary's view the primary stays `Unreachable`.

Workarounds that *do* work but are out of the chart's scope today:

1. **Match outbound to inbound.** Use a CNI / Service config that NAT-sources pod traffic to the Service ClusterIP (e.g. `service.kubernetes.io/topology-mode: PreferLocal` plus a Cilium / kube-router SNAT, or a sidecar that does the rewrite). Once outbound AXFR comes from the registered ClusterIP, zone transfer succeeds, TLSA syncs, DANE-EE validates.
2. **Provide a real cert from a shared CA.** Issue per-node certs from a CA whose root is in both pods' trust stores. PKIX then succeeds without needing DANE-EE / TLSA records at all. Doesn't fix catalog *content* sync, but takes the heartbeat failure off the critical path.

We previously misdiagnosed this as a missing flag in Technitium's heartbeat path. The upstream PR ([TechnitiumSoftware/DnsServer#1921](https://github.com/TechnitiumSoftware/DnsServer/pull/1921)) was correctly closed by the maintainer — DANE-EE *is* enabled on the heartbeat path; the issue is that the chart never gives the secondary's catalog zone a chance to sync. The full diagnosis trail lives in [`docs/upstream-pr.md`](docs/upstream-pr.md).

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

### ❤️ Personal Thanks

Building and maintaining open-source tools takes time and focus. I want to give a special thanks to **my wife, my daughter, and my baby boy**. Your support and patience allow me the space to be a "geek" and contribute back to the community. You are my greatest motivation\!

## ⚖️ Disclaimers & Licensing

### ⚠️ Not an Official Product

**I am not the author of Technitium.** This repository contains only the **Helm Chart** used to deploy the software. I am not affiliated with Technitium Software in any official capacity. For issues related to the DNS server software itself, please refer to the [official Technitium GitHub repository](https://github.com/TechnitiumSoftware/DnsServer).

### 🚫 No Liability

This Helm chart is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. **Use at your own risk.**

### 📄 License

This Helm chart is released under the [MIT License](https://opensource.org/licenses/MIT). Technitium DNS Server itself is released under its own respective license (GPLv3).
