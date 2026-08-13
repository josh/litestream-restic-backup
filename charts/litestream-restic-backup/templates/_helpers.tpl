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

{{- define "litestream-restic-backup.validate" -}}
{{- if not .Values.litestream.replicaURL -}}
{{- fail "litestream.replicaURL is required" -}}
{{- end -}}
{{- if not .Values.restic.repository -}}
{{- fail "restic.repository is required" -}}
{{- end -}}
{{- if .Values.database -}}
{{- fail "database.name is now restic.host" -}}
{{- end -}}
{{- if .Values.networkPolicy.egress.enabled -}}
{{- $extra := .Values.networkPolicy.egress.extraRules -}}
{{- if not (or .Values.networkPolicy.egress.restic.to $extra) -}}
{{- fail "networkPolicy.egress.enabled needs peers reaching restic.repository; set networkPolicy.egress.restic.to" -}}
{{- end -}}
{{- if not (or .Values.networkPolicy.egress.litestream.to $extra) -}}
{{- fail "networkPolicy.egress.enabled needs peers reaching the litestream replica; set networkPolicy.egress.litestream.to" -}}
{{- end -}}
{{- end -}}
{{- end -}}
