# 🌐 Technitium DNS Server Helm Chart

[](https://artifacthub.io/)

This Helm chart simplifies the deployment of **Technitium DNS Server** on Kubernetes. Technitium is an open-source authoritative as well as recursive DNS server that is designed to be self-hosted and privacy-focused.

## 🚀 Quick Start

To install the chart with the release name `my-dns`:

```bash
helm install technitium-dns-server technitium/ --set config.dnsDomain="dns-server"```
```

## ⚙️ Configuration

The following table lists the configurable parameters of the Technitium chart and their default values.

| Parameter | Description                                                       | Default                       | Required |
|-----------|-------------------------------------------------------------------|-------------------------------|:---:|
| 🔑 `config.dnsDomain` | The primary name used by the DNS Server for ID Only.              | `""`                          | **YES** |
| 🖼️ `image.repository` | Container image repository                                        | `technitium/dns-server`       | No |
| 🏷️ `image.tag` | Container image tag (defaults to `app version`)                   | `app version in Chart.yaml`   | No |
| 🔄 `config.recursion` | Recursion policy: `Allow`, `Deny`, `AllowOnlyForPrivateNetworks`. | `AllowOnlyForPrivateNetworks` | No |
| 🛡️ `config.enableBlocking` | Enables blocking using Blocked Zones and Block Lists.             | `true`                        | No |
| 📡 `config.forwarders` | Comma separated list of upstream forwarders.                      | `1.1.1.1, 8.8.8.8`            | No |
| 🔌 `service.type` | K8s Service type (`LoadBalancer`, `NodePort`, etc.)               | `LoadBalancer`                | No |
| 💾 `persistence.size` | Size of the persistent volume.                                    | `2Gi`                         | No |

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
