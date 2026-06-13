# Cluster sync on Kubernetes — post-mortem

This file used to host a draft PR against [TechnitiumSoftware/DnsServer](https://github.com/TechnitiumSoftware/DnsServer)
proposing that `ignoreCertificateErrors` from `initJoin` be persisted into
the heartbeat HttpApiClient ([PR #1921][pr]). **That diagnosis was wrong.**
The PR was correctly closed by the maintainer ([comment][cmt]) and this
note records the real cause so future readers don't repeat the mistake.

[pr]: https://github.com/TechnitiumSoftware/DnsServer/pull/1921
[cmt]: https://github.com/TechnitiumSoftware/DnsServer/pull/1921#issuecomment-4418573460

## What I thought was wrong

`ClusterNode.GetApiClient()` at `DnsServerCore/Cluster/ClusterNode.cs:196`
constructs every heartbeat `HttpApiClient` with `ignoreCertificateErrors:
false` hard-coded. The PR observed this and concluded that the
`ignoreCertificateErrors` value supplied at `/api/admin/cluster/initJoin`
time was being dropped on the floor for ongoing heartbeats.

## What's actually going on

`HttpApiClient`'s constructor (`DnsServerCore.HttpApi/HttpApiClient.cs:85`)
takes that flag and **toggles between two trust models**:

```csharp
if (ignoreCertificateErrors)
{
    handler.InnerHandler.SslOptions.RemoteCertificateValidationCallback =
        (...) => true;          // bypass everything
}
else
{
    handler.EnableDANE = true;  // validate via DANE-EE TLSA records
}
```

So passing `false` is not "use PKIX" — it's "use DANE-EE." Forcing
`true` would actively *disable* DANE-EE and is therefore worse than the
current behavior, not better.

The heartbeat *is* configured to use DANE-EE. It's failing because in
our deployment, the secondary's local catalog zone (`cluster-catalog.<cluster.domain>`)
is empty — it never finished its initial AXFR — so DANE-EE has no TLSA
records to validate against and the .NET HTTPS handler falls back to
strict PKIX, which sees a self-signed cert without a known root and
returns `UntrustedRoot`.

## Why the catalog zone never syncs (on Kubernetes)

The primary catalog zone is created at cluster init with a
per-zone "zone transfer allowed networks" list populated from each
cluster member's registered IP. With this Helm chart, that registered
IP is the secondary's **web Service ClusterIP** (chosen because pod IPs
are ephemeral). But when the secondary actually initiates the AXFR, the
TCP connection's source IP is the **pod IP**, not the Service ClusterIP
— Kubernetes does not SNAT outbound pod traffic to the ClusterIP. The
primary therefore refuses the transfer:

```
DNS Server refused a zone transfer request since the request IP address
is not allowed by the zone: cluster-catalog.ns.example.local
```

No catalog sync → no TLSA records on the secondary → DANE-EE has
nothing to validate → PKIX fallback → `UntrustedRoot`.

This is a chart-side problem (in fact, broadly a "Technitium clustering
on Kubernetes" problem), not a Technitium bug.

## What this means for the chart

There is no quick chart-only fix. Two viable approaches:

1. **SNAT outbound to the Service ClusterIP.** Requires CNI-specific
   plumbing (Cilium policy, kube-router, an ambient sidecar — varies by
   cluster). Outside the chart's reasonable scope.
2. **Issue per-node certs from a shared CA.** Heartbeats then validate
   via PKIX with a trusted root; DANE-EE / catalog sync becomes a
   nice-to-have rather than required. Larger chart surface (CA Secret,
   per-release cert generation, trust-bundle init container) and only
   addresses the heartbeat failure, not catalog *content* sync.

The chart currently ships with the limitation documented (see the
"Known limitation" section of the README) and `cluster.autoJoin`
defaulted on because joining itself succeeds and the API surface still
gives users a working multi-node admin view — just without true config
replication.

## Possible upstream feature requests

If you want to revisit this with upstream, the productive asks are
*about catalog sync*, not about cert validation:

- Allow catalog/cluster zones to authenticate AXFR via TSIG instead of
  source-IP allow-lists, so transport NAT doesn't break it.
- Permit CIDR entries (and not just specific IPs) in the per-zone
  transfer allow list so a whole pod CIDR can be permitted at once.
- Allow `cluster.init` / `initJoin` to register multiple IPs or a CIDR
  per node, so the chart could register both Service ClusterIP and pod
  CIDR.

None of those are needed for someone deploying on bare metal where
each node has a single stable IP and outbound source = inbound source.
That's the use case Technitium clustering was designed for, and it
works fine there — including the maintainer's own homelab.
