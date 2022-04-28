{{/*
Expand the name of the chart.
*/}}
{{- define "mlflow.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mlflow.fullname" -}}
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
{{- define "mlflow.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mlflow.labels" -}}
helm.sh/chart: {{ include "mlflow.chart" . }}
{{ include "mlflow.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mlflow.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mlflow.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "mlflow.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "mlflow.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Artifact Store
*/}}
{{- define "mlflow.artifactStore.accessKey" -}}
{{- if .Values.minio.enabled }}
{{- print .Values.minio.accessKey.password -}}
{{- else }}
{{- printf .Values.externalArtifactStore.accessKey -}}
{{- end }}
{{- end }}

{{- define "mlflow.artifactStore.secretKey" -}}
{{- if .Values.minio.enabled }}
{{- print .Values.minio.secretKey.password -}}
{{- else }}
{{- printf .Values.externalArtifactStore.secretKey -}}
{{- end }}
{{- end }}

{{- define "mlflow.artifactStore.storageHost" -}}
{{- if .Values.minio.enabled }}
{{- printf "http://%s-minio.%s.svc.cluster.local:%s" .Release.Name .Release.Namespace .Values.minio.containerPort }}
{{- end }}
{{- end }}

{{- define "mlflow.artifactStore.artifactRoot" -}}
{{- if .Values.minio.enabled }}
{{- printf "s3://%s/%s" .Values.minio.defaultBuckets .Values.minio.defaultPath}}
{{- else }}
{{- printf "%s://%s/%s" .Values.externalArtifactStore.type .Values.externalArtifactStore.bucket .Values.externalArtifactStore.path }}
{{- end }}
{{- end }}

{{- define "mlflow.artifactStore.externalMinio.endpoint" -}}
{{- if .Values.externalArtifactStore.externalMinio.enabled }}
{{- printf "http://%s:%g" .Values.externalArtifactStore.externalMinio.host .Values.externalArtifactStore.externalMinio.port }}
{{- else }}
{{- printf "" }}
{{- end }}
{{- end }}

{{/*
Database
*/}}
{{- define "mlflow.backendStoreURI" -}}
{{- if .Values.postgresql.enabled -}}
    {{- $db_conn_host  := (printf "%s-postgresql.%s.svc.cluster.local" .Release.Name .Release.Namespace) -}}
    {{- $db_conn_port  := "5432" -}}
    {{- $db_conn_user  := .Values.postgresql.postgresqlUsername -}}
    {{- $db_conn_password  := .Values.postgresql.postgresqlPassword -}}
    {{- $db_conn_db  := .Values.postgresql.postgresqlDatabase -}}
    {{- $db_conn_type  := "postgresql+psycopg2" -}}
    {{- printf "%s://%s:%s@%s:%s/%s" $db_conn_type $db_conn_user $db_conn_password $db_conn_host $db_conn_port $db_conn_db -}}
{{- else -}}
    {{- $db_conn_host  := .Values.externalDatabase.host -}}
    {{- $db_conn_port  := .Values.externalDatabase.port | toString -}}
    {{- $db_conn_user  := .Values.externalDatabase.user -}}
    {{- $db_conn_password  := .Values.externalDatabase.password -}}
    {{- $db_conn_db := .Values.externalDatabase.database -}}
    {{- $db_conn_properties  := .Values.externalDatabase.properties -}}
    {{- if eq "postgres" .Values.externalDatabase.type -}}
        {{- printf "postgresql+psycopg2://%s:%s@%s:%s/%s?%s" $db_conn_user $db_conn_password $db_conn_host $db_conn_port $db_conn_db $db_conn_properties -}}
    {{- else if eq "mysql" .Values.externalDatabase.type -}}
        {{- printf "mysql+mysqldb://%s:%s@%s:%s/%s?%s" $db_conn_user $db_conn_password $db_conn_host $db_conn_port $db_conn_db $db_conn_properties -}}
    {{- else -}}
        {{- fail "value for .Values.externalDatabase.type must be one of: postgres, mysql" -}}
    {{- end -}}
{{- end -}}{{- end -}}
