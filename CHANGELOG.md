# Helm Technitium Chart

## v0.3.0 - 2026-09-26

### What Changed 👀

#### 🚀 Features

- feat: register cluster nodes at stable ClusterIPs and allow pod networks @Bugs5382 (#48)
- feat: run without a PVC, with zone bootstrap on every start @Bugs5382 (#47)
- feat: add service labels passthrough to the Service templates @Bugs5382 (#40)
- feat: enforce Recreate update strategy (reject RollingUpdate) @Bugs5382 (#31)

#### 🐛 Bug Fixes

- fix(ci-values): use hash license headers in the example values files @Bugs5382 (#45)
- fix(cluster-join): resolve pod IPs through EndpointSlices @Bugs5382 (#39)

#### 📄 Documentation

- docs(readme): apply the lite emoji treatment @Bugs5382 (#36)

#### 🧩 Dependency Updates

- chore(deps): bump Technitium DNS Server to 15.5.1 @Bugs5382 (#46)

### Extra

**Full Changelog**: https://github.com/Bugs5382/helm-technitium-chart/compare/v0.2.0...v0.3.0

## v0.2.0 - 2026-06-13

### What Changed 👀

#### 🚀 Features

- feat: updates @Bugs5382 (#23)

### Extra

**Full Changelog**: https://github.com/Bugs5382/helm-technitium-chart/compare/v0.1.0...v0.2.0

## v0.1.0 - 2026-04-24

### What Changed 👀

#### 🚀 Features

- feat: added all env @Bugs5382 (#13)
- feat: helm chart creation @Bugs5382 (#2)

#### 🐛 Bug Fixes

- fix: updated pvc vol mount @Bugs5382 (#11)

### Extra

**Full Changelog**: https://github.com/Bugs5382/helm-technitium-chart/compare/...v0.1.0
