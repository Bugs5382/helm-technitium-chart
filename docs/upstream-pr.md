# Upstream issue + PR for TechnitiumSoftware/DnsServer

This is a ready-to-submit issue and PR description for the
[TechnitiumSoftware/DnsServer](https://github.com/TechnitiumSoftware/DnsServer)
repository. Submit this when you want to upstream the fix discovered while
building the Helm chart in this repo.

The repro and analysis below are taken verbatim from a working two-instance
deployment on Kubernetes (k0s, single-node, Technitium image
`technitium/dns-server:15.1.0`). The cluster joined successfully via
`/api/admin/cluster/initJoin` with `ignoreCertificateErrors=true`, but
subsequent heartbeats from the secondary to the primary failed continuously
with PKIX validation errors against the primary's self-signed cert.

The exact code path described below is **unchanged in the latest release
v15.2.0** (tagged 2026-05-09) — `ClusterNode.cs:196` still hard-codes
`ignoreCertificateErrors: false`, and the v15.2 changelog's cluster fixes
(API token sync; SSO group map sync) are unrelated.

---

## Suggested issue title

> Cluster heartbeats fail with `UntrustedRoot` against self-signed peer cert — `ignoreCertificateErrors` from `initJoin` is not honored at runtime

## Suggested PR title

> Honor `ignoreCertificateErrors` for cluster heartbeats; expose it via `setOptions`

---

## Summary

`POST /api/admin/cluster/initJoin` accepts `ignoreCertificateErrors=true`,
which lets a Secondary node bootstrap-join a Primary that is using the
auto-generated self-signed HTTPS certificate (the default for users who
follow the "Initialize New Cluster" wizard without manually configuring a
PKI-trusted cert first).

After the join completes, however, the value of `ignoreCertificateErrors`
is discarded. Every subsequent heartbeat constructs a fresh `HttpApiClient`
with `ignoreCertificateErrors: false` hard-coded, so the heartbeats
immediately fail and the Secondary node reports the Primary as
`Unreachable`. From the Secondary's `/var/log/technitium/dns/*.log`:

```
[2026-05-11 04:59:47 UTC] Heartbeat failed for Primary node 'tech-a.ns.example.local (10.102.8.71)'.
System.Net.Http.HttpRequestException: The remote certificate is invalid because of errors
  in the certificate chain: UntrustedRoot (tech-a.ns.example.local:53443)
 ---> System.Security.Authentication.AuthenticationException: The remote certificate is
       invalid because of errors in the certificate chain: UntrustedRoot
   at System.Net.Security.SslStream.SendAuthResetSignal(...)
   ...
   at DnsServerCore.HttpApi.HttpApiClient.GetClusterStateAsync(...) in HttpApiClient.cs:line 389
   at DnsServerCore.Cluster.ClusterNode.GetClusterStateAsync(...) in ClusterNode.cs:line 517
   at DnsServerCore.Cluster.ClusterNode.HeartbeatTimerCallbackAsync(...) in ClusterNode.cs:line 224
```

The
[clustering blog post](https://blog.technitium.com/2025/11/understanding-clustering-and-how-to.html)
states that "Once a node joins the Cluster, it uses DANE-EE for server
authentication," but in practice the heartbeat path goes through plain
`SslStream` PKIX validation against the system trust store; the
self-signed cert (or, more generally, any non-publicly-trusted cert)
fails. Users who want clustering "just to work" with the default
auto-generated self-signed cert currently have to manually provision a
PKI-trusted certificate before initialization, which is unfortunate for
private / homelab / Kubernetes deployments where there is no chain back
to a public CA.

## Reproduction

1. Deploy two Technitium 15.1.0 instances on a private network (any two
   Linux hosts, two containers, two pods — anywhere they can reach each
   other on TCP 53443).
2. On node-A: log into the web console, **Administration → Cluster →
   Initialize New Cluster**, accept the auto-generated self-signed cert.
   Note that `clusterInitialized=true` afterwards.
3. On node-B: **Administration → Cluster → Join Cluster** (or call
   `POST /api/admin/cluster/initJoin?...&ignoreCertificateErrors=true`).
   The join completes with `status:ok`. `clusterInitialized=true` on B.
4. From node-A's `/api/admin/cluster/state` you see node-B as
   `state: Connected`.
5. From node-B's `/api/admin/cluster/state` you see node-A as
   `state: Unreachable`, and node-B's DNS server log fills with the
   stack trace above on every heartbeat retry interval.

## Root cause

`DnsServerCore/Cluster/ClusterNode.cs` at the start of every heartbeat /
config-refresh cycle calls `GetApiClient()`. That method builds a fresh
`HttpApiClient` with `ignoreCertificateErrors` hard-coded to `false`:

```csharp
// DnsServerCore/Cluster/ClusterNode.cs
//
// line 189
private HttpApiClient GetApiClient()
{
    if (_state == ClusterNodeState.Self)
        throw new InvalidOperationException();

    if (_apiClient is null)
    {
        _apiClient = new HttpApiClient(
            _url,
            _clusterManager.DnsWebService.DnsServer.Proxy,
            _clusterManager.DnsWebService.DnsServer.IPv6Mode,
            false,                                                // <-- hard-coded ignoreCertificateErrors
            new InternalDnsClient(_clusterManager.DnsWebService.DnsServer, this));
        ...
    }
}
```

For comparison, the bootstrap join *does* honor the flag
(`DnsServerCore/Cluster/ClusterManager.cs:1347`):

```csharp
using HttpApiClient primaryNodeApiClient = new HttpApiClient(
    primaryNodeUrl,
    _dnsWebService.DnsServer.Proxy,
    _dnsWebService.DnsServer.IPv6Mode,
    ignoreCertificateErrors,                                    // <-- threaded through from API param
    new InternalDnsClient(_dnsWebService.DnsServer, primaryNodeIpAddresses),
    TimeSpan.FromSeconds(300));
```

So the user expresses consent to trust self-signed certs at join time,
but that consent is not persisted into cluster state.

## Proposed fix

Persist the flag as a cluster-wide option and use it in
`ClusterNode.GetApiClient()`. Expose it via the existing
`setOptions` endpoint so an operator can toggle it later (e.g., turn it
off after migrating to a PKI-trusted cert).

This is a small, additive change: a new boolean settings field, a new
optional `setOptions` parameter, and one line changed in
`GetApiClient()`. Default value preserves existing strict behavior;
users who explicitly opted into `ignoreCertificateErrors=true` at join
time get the flag propagated automatically.

### Suggested diff (illustrative)

`DnsServerCore/Cluster/ClusterManager.cs`

```diff
 sealed class ClusterManager : IDisposable
 {
     ...
     int _heartbeatRefreshIntervalSeconds = 30;
     int _heartbeatRetryIntervalSeconds = 10;
     int _configRefreshIntervalSeconds = 900;
     int _configRetryIntervalSeconds = 60;
+    bool _ignoreCertificateErrors;
     ...

     public int HeartbeatRefreshIntervalSeconds { ... }
     public int HeartbeatRetryIntervalSeconds  { ... }
     public int ConfigRefreshIntervalSeconds   { ... }
     public int ConfigRetryIntervalSeconds     { ... }
+    public bool IgnoreCertificateErrors
+    {
+        get => _ignoreCertificateErrors;
+        set => _ignoreCertificateErrors = value;
+    }

     // InitializeAndJoinClusterAsync — persist the user's intent:
     public async Task InitializeAndJoinClusterAsync(..., bool ignoreCertificateErrors = false, ...)
     {
         ...
         using HttpApiClient primaryNodeApiClient = new HttpApiClient(
             primaryNodeUrl, ..., ignoreCertificateErrors, ...);
         ...
+        _ignoreCertificateErrors = ignoreCertificateErrors;
         // (persist alongside the other settings during the save call that
         // already happens at the end of this method)
     }
 }
```

`DnsServerCore/Cluster/ClusterNode.cs`

```diff
 private HttpApiClient GetApiClient()
 {
     if (_state == ClusterNodeState.Self)
         throw new InvalidOperationException();

     if (_apiClient is null)
     {
         _apiClient = new HttpApiClient(
             _url,
             _clusterManager.DnsWebService.DnsServer.Proxy,
             _clusterManager.DnsWebService.DnsServer.IPv6Mode,
-            false,
+            _clusterManager.IgnoreCertificateErrors,
             new InternalDnsClient(_clusterManager.DnsWebService.DnsServer, this));
         ...
     }
 }
```

`/api/admin/cluster/primary/setOptions` (web-service handler — wherever
`heartbeatRefreshIntervalSeconds` etc. are read from the query string):

```diff
 if (request.Query.TryGetValue("configRetryIntervalSeconds", out StringValues v))
     ClusterManager.ConfigRetryIntervalSeconds = int.Parse(v);

+if (request.Query.TryGetValue("ignoreCertificateErrors", out StringValues v2))
+    ClusterManager.IgnoreCertificateErrors = bool.Parse(v2);
```

Plus the persistence path that already writes the other cluster options
needs to read/write the new field. (I haven't included those edits here
because the surrounding boilerplate varies by `ClusterManager`'s on-disk
format version.)

### Documentation

Two small doc tweaks:

- `APIDOCS.md` → `Set Cluster Options`: list the new
  `ignoreCertificateErrors` parameter.
- `APIDOCS.md` → `Initialize And Join Cluster`: note that the flag passed
  here is also persisted as the cluster-wide default and will continue
  to apply to heartbeats; it can be flipped off later via `setOptions`
  once a trusted cert is in place.

## Why not implement DANE-EE properly instead?

The blog post implies DANE-EE is in use, and the `clusterCatalog` zone
already holds `TLSA` records keyed off each node. So an alternative,
larger fix is to have the heartbeat client genuinely use DANE-EE
(consult the cluster zone's TLSA record and validate the peer cert
hash against it). That would be the more architecturally correct fix
and would not require any operator opt-in.

The `ignoreCertificateErrors` propagation above is meant to be the
smaller stop-gap that closes the practical gap today while preserving
the option to add DANE-EE later. Happy to revise this PR — or split into
"stop-gap" and "DANE-EE" PRs — based on your preference.

## Testing notes

- Tested by hand on a single-node k0s cluster with two Technitium 15.1.0
  releases deployed side-by-side; the flag was set via
  `initJoin?ignoreCertificateErrors=true` and persisted using a local
  patched build. After the fix, both nodes report each other as
  `state: Connected` and `Heartbeat failed` log entries stop appearing.
- No unit-test changes were needed because `HttpApiClient` already has
  the `ignoreCertificateErrors` constructor parameter exercised by the
  initJoin path.


Upstream PR located [here](https://github.com/TechnitiumSoftware/DnsServer/pull/1921).
