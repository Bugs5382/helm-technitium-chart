# 🌐 Technitium DNS Server Helm Chart

[](https://artifacthub.io/)

This Helm chart simplifies the deployment of **Technitium DNS Server** on Kubernetes. Technitium is an open-source authoritative as well as recursive DNS server that is designed to be self-hosted and privacy-focused.

## 🚀 Quick Start

To install the chart with the release name `my-dns`:

```bash
helm install technitium-dns-server technitium --set config.dnsDomain="dns-server" [ -n technitium ]
```

## ⚙️ Configuration

The following table lists the configurable parameters of the Technitium chart and their default values.

Here is your updated README configuration table. I've organized it into logical sections—**Core**, **Web/Security**, **Network/DNS**, and **Infrastructure**—to keep it readable as it grows.

### Configuration Parameters

| Parameter                               | Description | Default | Required |
|:----------------------------------------| :--- | :--- | :---: |
| **Image Settings**                      | | | |
| 🖼️ `image.repository`                  | Container image repository. | `technitium/dns-server` | No |
| 🏷️ `image.tag`                         | Container image tag. | `Chart.AppVersion` | No |
| 🔄 `image.pullPolicy`                   | K8s image pull policy. | `IfNotPresent` | No |
| **DNS Core Config**                     | | | |
| 🔑 `config.dnsDomain`                   | The primary domain name used by the DNS Server to identify itself. | `""` | **YES** |
| 🛡️ `config.enableBlocking`             | Enables blocking using Blocked Zones and Block Lists. | `true` | No |
| 📡 `config.forwarders`                  | Comma separated list of upstream forwarders. | `1.1.1.1, 8.8.8.8` | No |
| 🔌 `config.forwarderProtocol`           | Protocol for forwarders (`Udp`, `Tcp`, `Tls`, `Https`). | `Tcp` | No |
| 🔄 `config.recursion`                   | Recursion policy: `Allow`, `Deny`, `AllowOnlyForPrivateNetworks`, `UseSpecifiedNetworkACL`. | `AllowOnlyForPrivateNetworks` | No |
| 📝 `config.recursionAcl`                | Comma separated list of IPs/CIDRs to allow (use `!` to deny). | `""` | No |
| 🕒 `config.logLocalTime`                | Use local time instead of UTC for logging. | `true` | No |
| **Web UI & Security**                   | | | |
| 👤 `config.adminPassword`               | Plain text password for the admin user (best set via Secret). | `""` | No |
| 🔒 `config.webServiceEnableHttps`       | Enables HTTPS for the web management console. | `false` | No |
| 📜 `config.webServiceUseSelfSignedCert` | Generates a self-signed TLS cert for the Web UI. | `false` | No |
| 📂 `config.webServiceTlsCertificatePath`| Container path to a `.pfx` certificate file. | `/etc/dns/tls/cert.pfx`| No |
| ↪️ `config.webServiceHttpToTlsRedirect` | Redirects HTTP Web UI traffic to HTTPS. | `false` | No |
| **Port Toggles (Enabled Flags)**        | | | |
| 🌐 `ports.webHttp`                      | Web UI (HTTP) on port `5380`. | `true` | No |
| 🔐 `ports.webHttps`                     | Web UI (HTTPS) on port `53443`. | `false` | No |
| 🚀 `ports.doq.enabled`                  | Enable DNS-over-QUIC (UDP) on port `853`. | `false` | No |
| 🛡️ `ports.dot.enabled`                 | Enable DNS-over-TLS (TCP) on port `853`. | `false` | No |
| 🔗 `ports.doh.enabled`                  | Enable DNS-over-HTTPS (TCP/UDP) on port `443`. | `false` | No |
| 🌉 `ports.dohProxy.enabled`             | Enable DNS-over-HTTP (Proxy) on port `8053`. | `false` | No |
| 🏠 `ports.dhcp.enabled`                 | Enable DHCP service on port `67`. | `false` | No |
| **Infrastructure**                      | | | |
| 🔌 `service.type`                       | K8s Service type (`LoadBalancer`, `ClusterIP`, `NodePort`). | `LoadBalancer` | No |
| 🆔 `serviceAccount.create`              | Whether to create a dedicated Service Account. | `true` | No |
| 💾 `persistence.size`                   | Size of the persistent volume for config and logs. | `2Gi` | No |
| 💾 `persistence.storageClass`           | Storage class for the PVC. | `""` | No |

> **Note:** If `ports.dhcp.enabled` is set to `true`, the pod may require `hostNetwork: true` or specific CNI configurations to broadcast DHCP discovery packets correctly.

## 🔐 Security & Admin Password

By default, this chart generates a random 16-character administrative password if `config.adminPassword` is left empty in your `values.yaml`.

To retrieve your generated password after deployment, run:

```bash
kubectl get secret technitium-admin -o jsonpath="{.data.password}" | base64 --decode; echo
```

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

Building and maintaining open-source tools takes time and focus. I want to give a special thanks to **my wife, my daughter, and my son**. Your support and patience allow me the space to be a "geek" and contribute back to the community. You are my greatest motivation\!

## ⚖️ Disclaimers & Licensing

### ⚠️ Not an Official Product

**I am not the author of Technitium.** This repository contains only the **Helm Chart** used to deploy the software. I am not affiliated with Technitium Software in any official capacity. For issues related to the DNS server software itself, please refer to the [official Technitium GitHub repository](https://github.com/TechnitiumSoftware/DnsServer).

### 🚫 No Liability

This Helm chart is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.

In no event shall the authors or copyright holders be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software. **Use at your own risk.**

### 📄 License

This Helm chart is released under the [MIT License](https://opensource.org/licenses/MIT). Technitium DNS Server itself is released under its own respective license (GPLv3).
