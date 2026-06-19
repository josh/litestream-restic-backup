{{/* Expand the name of the chart. */}}
{{- define "litestream-restic-backup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Fully qualified app name. */}}
{{- define "litestream-restic-backup.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "litestream-restic-backup.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "litestream-restic-backup.labels" -}}
helm.sh/chart: {{ include "litestream-restic-backup.chart" . }}
{{ include "litestream-restic-backup.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "litestream-restic-backup.selectorLabels" -}}
app.kubernetes.io/name: {{ include "litestream-restic-backup.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Image reference, honoring optional digest pin. */}}
{{- define "litestream-restic-backup.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- if .Values.image.digest -}}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end -}}
{{- end -}}

{{/* Name of the chart-generated ConfigMap holding the litestream config. */}}
{{- define "litestream-restic-backup.configMapName" -}}
{{- printf "%s-litestream" (include "litestream-restic-backup.fullname" .) -}}
{{- end -}}

{{/* litestream.yml content: verbatim config if given, else synthesized from replicaURL.
     This is a ConfigMap (not a Secret) — keep credentials out of it; use an
     existingConfigSecret for credential-bearing configs. backup.sh restores the db at the
     fixed path /work/db.sqlite, so the db `path` here must match that. */}}
{{- define "litestream-restic-backup.litestreamConfig" -}}
{{- if .Values.litestream.config -}}
{{ .Values.litestream.config }}
{{- else -}}
dbs:
  - path: /work/db.sqlite
    replicas:
      - url: {{ .Values.litestream.replicaURL | quote }}
{{- end -}}
{{- end -}}

{{- define "litestream-restic-backup.validate" -}}
{{- if .Values.litestream.existingConfigSecret -}}
  {{/* user supplies the whole config; nothing to require here */}}
{{- else if and .Values.litestream.replicaURL .Values.litestream.config -}}
{{- fail "set only one of litestream.replicaURL or litestream.config" -}}
{{- else if and (not .Values.litestream.replicaURL) (not .Values.litestream.config) -}}
{{- fail "set litestream.replicaURL (or litestream.config / existingConfigSecret)" -}}
{{- end -}}
{{- if not .Values.restic.repository -}}
{{- fail "restic.repository is required" -}}
{{- end -}}
{{- end -}}
