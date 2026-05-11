{{/*
MIT License

Copyright (c) 2026 Shane & Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "technitium.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this.
*/}}
{{- define "technitium.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "technitium.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "technitium.labels" -}}
helm.sh/chart: {{ include "technitium.chart" . }}
{{ include "technitium.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- $cluster := include "technitium.clusterLabels" . | trim -}}
{{- if $cluster }}
{{ $cluster }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "technitium.selectorLabels" -}}
app.kubernetes.io/name: {{ include "technitium.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Cluster discovery labels. Emitted only when cluster.enabled is true so
sibling releases can be listed with:
  kubectl get pods -l technitium.io/cluster-domain=<domain>
*/}}
{{- define "technitium.clusterLabels" -}}
{{- if .Values.cluster.enabled }}
{{- $domain := required "cluster.domain is required when cluster.enabled" .Values.cluster.domain }}
technitium.io/cluster-domain: {{ $domain | replace "." "-" | trunc 63 | trimSuffix "-" | quote }}
technitium.io/cluster-role: {{ ternary "secondary" "primary" (ne (.Values.cluster.primaryReleaseName | toString) "") | quote }}
{{- end }}
{{- end }}

{{/*
Effective HTTPS toggle. Clustering needs DANE-EE TLS on the web service, so
cluster.enabled + cluster.autoHttps implies HTTPS even if the user did not
explicitly opt in via config.webServiceEnableHttps.
*/}}
{{- define "technitium.httpsEnabled" -}}
{{- if or .Values.config.webServiceEnableHttps (and .Values.cluster.enabled .Values.cluster.autoHttps) -}}
true
{{- end -}}
{{- end }}

{{/*
Effective self-signed cert toggle. Same reasoning as httpsEnabled.
*/}}
{{- define "technitium.selfSignedCertEnabled" -}}
{{- if or .Values.config.webServiceUseSelfSignedCert (and .Values.cluster.enabled .Values.cluster.autoHttps) -}}
true
{{- end -}}
{{- end }}

{{/*
In-cluster web URL for an arbitrary release name in this release's namespace.
Usage:
  {{ include "technitium.webUrl" (dict "root" . "release" "my-primary") }}
*/}}
{{- define "technitium.webUrl" -}}
{{- $root := .root -}}
{{- $name := default $root.Chart.Name $root.Values.nameOverride -}}
{{- $full := printf "%s-%s" .release $name | trunc 63 | trimSuffix "-" -}}
{{- if eq (include "technitium.httpsEnabled" $root) "true" -}}
https://{{ $full }}-web.{{ $root.Release.Namespace }}.svc.cluster.local:{{ $root.Values.ports.webHttps | default 53443 }}
{{- else -}}
http://{{ $full }}-web.{{ $root.Release.Namespace }}.svc.cluster.local:{{ $root.Values.ports.webHttp | default 5380 }}
{{- end -}}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "technitium.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "technitium.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}