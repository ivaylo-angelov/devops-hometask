{{- define "my-backend-app.name" -}}
{{- .Chart.Name | trimSuffix "-" -}}
{{- end -}}

{{- define "my-backend-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trimSuffix "-" -}}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
