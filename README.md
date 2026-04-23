# 🌐 Technitium DNS Server Helm Chart

This Helm chart simplifies the deployment of **Technitium DNS Server** on Kubernetes. Technitium is an open-source authoritative as well as recursive DNS server that is designed to be self-hosted and privacy-focused.

## 🚀 Quick Start

To install the chart with the release name `my-dns`:

```bash
helm install my-dns technitium
--set config.dnsDomain="dns-server"
--namespace technitium
--create-namespace
```

## ⚙️ Configuration

The following table lists the configurable parameters of the Technitium chart and their default values.

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

> **Note:** If `ports.dhcp.enabled` is set to `true`, the pod may require `hostNetwork: true` or specific CNI configurations to broadcast DHCP discovery packets correctly.

## 🔐 Security & Admin Password

By default, this chart generates a random 16-character administrative password if `config.adminPassword` is left empty in your `values.yaml`.

To retrieve your generated password after deployment, run:

```bash
kubectl get secret my-dns-admin -n technitium -o jsonpath="{.data.password}" | base64 --decode; echo
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
