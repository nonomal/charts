{{/* vim: set filetype=mustache: */}}

{{/*
Fully qualified app name for PostgreSQL
*/}}
{{- define "thanos.minio.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- printf "%s-minio" .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-minio" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-minio" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Thanos image name
*/}}
{{- define "thanos.image" -}}
{{- include "common.images.image" ( dict "imageRoot" .Values.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper init container volume-permissions image name
*/}}
{{- define "thanos.volumePermissions.image" -}}
{{- include "common.images.image" ( dict "imageRoot" .Values.volumePermissions.image "global" .Values.global ) -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "thanos.imagePullSecrets" -}}
{{- include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.volumePermissions.image) "global" .Values.global) -}}
{{- end -}}

{{/*
Return the Thanos Objstore configuration secret.
*/}}
{{- define "thanos.objstoreSecretName" -}}
{{- if .Values.existingObjstoreSecret -}}
    {{- printf "%s" (tpl .Values.existingObjstoreSecret $) -}}
{{- else -}}
    {{- printf "%s-objstore-secret" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created
*/}}
{{- define "thanos.createObjstoreSecret" -}}
{{- if and .Values.objstoreConfig (not .Values.existingObjstoreSecret) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return a YAML of either .Values.query or .Values.querier
If .Values.querier is used, we merge in the defaults from .Values.query, giving preference to .Values.querier
*/}}
{{- define "thanos.query.values" -}}
{{- if .Values.querier -}}
    {{- if .Values.query -}}
        {{- mergeOverwrite .Values.query .Values.querier | toYaml -}}
    {{- else -}}
        {{- .Values.querier | toYaml -}}
    {{- end -}}
{{- else -}}
    {{- .Values.query | toYaml -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Query Service Discovery configuration configmap.
*/}}
{{- define "thanos.query.SDConfigmapName" -}}
{{- $query := (include "thanos.query.values" . | fromYaml) -}}
{{- if $query.existingSDConfigmap -}}
    {{- printf "%s" (tpl $query.existingSDConfigmap $) -}}
{{- else -}}
    {{- printf "%s-query-sd-configmap" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.query.createSDConfigmap" -}}
{{- $query := (include "thanos.query.values" . | fromYaml) -}}
{{- if and $query.sdConfig (not $query.existingSDConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Ruler configuration configmap.
*/}}
{{- define "thanos.ruler.configmapName" -}}
{{- if .Values.ruler.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.ruler.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-ruler-configmap" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.ruler.createConfigmap" -}}
{{- if and .Values.ruler.config (not .Values.ruler.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos storegateway configuration configmap.
*/}}
{{- define "thanos.storegateway.configmapName" -}}
{{- if .Values.storegateway.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.storegateway.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-storegateway-configmap" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Query Frontend configuration configmap.
*/}}
{{- define "thanos.queryFrontend.configmapName" -}}
{{- if .Values.queryFrontend.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.queryFrontend.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-query-frontend-configmap" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.queryFrontend.createConfigmap" -}}
{{- if and .Values.queryFrontend.config (not .Values.queryFrontend.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created
*/}}
{{- define "thanos.storegateway.createConfigmap" -}}
{{- if and .Values.storegateway.config (not .Values.storegateway.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the Thanos Compactor pvc name
*/}}
{{- define "thanos.compactor.pvcName" -}}
{{- if .Values.compactor.persistence.existingClaim -}}
    {{- printf "%s" (tpl .Values.compactor.persistence.existingClaim $) -}}
{{- else -}}
    {{- printf "%s-compactor" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Check if there are rolling tags in the images
*/}}
{{- define "thanos.checkRollingTags" -}}
{{- include "common.warnings.rollingTag" .Values.image -}}
{{- include "common.warnings.rollingTag" .Values.volumePermissions.image -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "thanos.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "thanos.validateValues.objstore" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.ruler.alertmanagers" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.ruler.config" .) -}}
{{- $messages := append $messages (include "thanos.validateValues.sharded.service" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Objstore configuration */}}
{{- define "thanos.validateValues.objstore" -}}
{{- if and (or .Values.bucketweb.enabled .Values.compactor.enabled .Values.ruler.enabled .Values.storegateway.enabled .Values.receive.enabled) (not (include "thanos.createObjstoreSecret" .)) ( not .Values.existingObjstoreSecret) -}}
thanos: objstore configuration
    When enabling Bucket Web, Compactor, Ruler, Store or Receive Gateway component,
    you must provide a valid objstore configuration.
    There are three alternatives to provide it:
      1) Provide it using the 'objstoreConfig' parameter
      2) Provide it using an existing Secret and using the 'existingObjstoreSecret' parameter
      3) Put your objstore.yml under the 'files/conf/' directory
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Ruler Alertmanager(s) */}}
{{- define "thanos.validateValues.ruler.alertmanagers" -}}
{{/* Check the emptiness of the values */}}
{{- if and .Values.ruler.enabled ( and (empty .Values.ruler.alertmanagers) (empty .Values.ruler.alertmanagersConfig)) -}}
thanos: ruler alertmanagers
    When enabling Ruler component, you must provide either alermanagers URL(s) or an alertmanagers configuration.
    See https://github.com/thanos-io/thanos/blob/ef94b7e6468d94e2c47943ebf5fc6db24c48d867/docs/components/rule.md#flags and https://github.com/thanos-io/thanos/blob/ef94b7e6468d94e2c47943ebf5fc6db24c48d867/docs/components/rule.md#Configuration for more information.
{{- end -}}
{{/* Check that the values are defined in a mutually exclusive manner */}}
{{- if and .Values.ruler.enabled .Values.ruler.alertmanagers .Values.ruler.alertmanagersConfig -}}
thanos: ruler alertmanagers
    Only one of the following can be used at one time:
        * .Values.ruler.alertmanagers
        * .Values.ruler.alertmanagersConfig
    Otherwise, the configurations will collide and Thanos will error out. Please consolidate your configuration
    into one of the above options.
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - Ruler configuration */}}
{{- define "thanos.validateValues.ruler.config" -}}
{{- if and .Values.ruler.enabled (not (include "thanos.ruler.createConfigmap" .)) (not .Values.ruler.existingConfigmap) -}}
thanos: ruler configuration
    When enabling Ruler component, you must provide a valid configuration.
    There are three alternatives to provide it:
      1) Provide it using the 'ruler.config' parameter
      2) Provide it using an existing Configmap and using the 'ruler.existingConfigmap' parameter
      3) Put your ruler.yml under the 'files/conf/' directory
{{- end -}}
{{- end -}}

{{/* Validate values of Thanos - number of sharded service properties */}}
{{- define "thanos.validateValues.sharded.service" -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.clusterIPs) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.clusterIPs "context" $) ) }}
thanos: storegateway.sharded.service.clusterIPs
    The number of shards does not match the number of ClusterIPs $.Values.storegateway.sharded.service.clusterIPs
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.loadBalancerIPs) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.loadBalancerIPs "context" $) ) }}
thanos: storegateway.sharded.service.loadBalancerIPs
    The number of shards does not match the number of loadBalancerIPs $.Values.storegateway.sharded.service.loadBalancerIPs
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.http.nodePorts) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.http.nodePorts "context" $) ) }}
thanos: storegateway.sharded.service.http.nodePorts
    The number of shards does not match the number of http.nodePorts $.Values.storegateway.sharded.service.http.nodePorts
{{- end -}}
{{- end -}}
{{- if and .Values.storegateway.sharded.enabled (not (empty .Values.storegateway.sharded.service.grpc.nodePorts) ) -}}
{{- if eq "false" (include "thanos.validateValues.storegateway.sharded.length" (dict "property" $.Values.storegateway.sharded.service.grpc.nodePorts "context" $) ) }}
thanos: storegateway.sharded.service.grpc.nodePorts
    The number of shards does not match the number of grpc.nodePorts $.Values.storegateway.sharded.service.grpc.nodePorts
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "thanos.validateValues.storegateway.sharded.length" -}}
{{/* Get number of shards */}}
{{- $shards := int 0 }}
{{- if .context.Values.storegateway.sharded.hashPartitioning.shards }}
  {{- $shards = int .context.Values.storegateway.sharded.hashPartitioning.shards }}
{{- else }}
  {{- $shards = len .context.Values.storegateway.sharded.timePartitioning }}
{{- end }}
{{- $propertyLength := (len .property) -}}
{{/* Validate property */}}
{{- if ne $shards $propertyLength -}}
false
{{- end }}
{{- end }}

{{/* Service account name
Usage:
{{ include "thanos.serviceAccount.name" (dict "component" "bucketweb" "context" $) }}
*/}}
{{- define "thanos.serviceAccount.name" -}}
{{- $name := printf "%s-%s" (include "common.names.fullname" .context) .component -}}

{{- if .context.Values.existingServiceAccount -}}
    {{- $name = .context.Values.existingServiceAccount -}}
{{- end -}}

{{- $component := index .context.Values .component -}}
{{- if $component.serviceAccount.existingServiceAccount -}}
    {{- $name = $component.serviceAccount.existingServiceAccount -}}
{{- end -}}

{{- printf "%s" $name -}}
{{- end -}}

{{/* Service account use existing
{{- include "thanos.serviceAccount.useExisting" (dict "component" "bucketweb" "context" $) -}}
*/}}
{{- define "thanos.serviceAccount.useExisting" -}}
{{- $component := index .context.Values .component -}}
{{- if .context.Values.existingServiceAccount -}}
    {{- true -}}
{{- else if $component.serviceAccount.existingServiceAccount -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a hashring configmap object should be created
*/}}
{{- define "thanos.receive.createConfigmap" -}}
{{- if and .Values.receive.enabled (not .Values.receive.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}


{{/* Return the proper pod fqdn of the replica.
Usage:
{{ include "thanos.receive.podFqdn" (dict "root" . "extra" $suffix ) }}
*/}}
{{- define "thanos.receive.podFqdn" -}}
{{- printf "\"%s-receive-%d.%s-receive-headless.%s.svc.%s:10901\"" (include "common.names.fullname" .root ) .extra (include "common.names.fullname" .root ) .root.Release.Namespace .root.Values.clusterDomain -}}
{{- end -}}

{{/* Returns a proper configuration when no config is specified
Usage:
{{ include "thanos.receive.config" . }}
*/}}
{{- define "thanos.receive.config" -}}
{{- if not .Values.receive.config -}}
{{- if .Values.receive.service.additionalHeadless -}}
{{- $count := int .Values.receive.replicaCount -}}
{{- $endpoints_dict := dict "endpoints" (list)  -}}
{{- $root := . -}}
{{- range $i := until $count -}}
{{- $data := dict "root" $root "extra" $i -}}
{{- $noop := (include "thanos.receive.podFqdn" $data) | append $endpoints_dict.endpoints | set $endpoints_dict "endpoints" -}}
{{- end -}}
[
  {
    "endpoints": [
{{ join ",\n" $endpoints_dict.endpoints | indent 6 }}
    ]
  }
]
{{- else -}}
[
  {
    "endpoints": [
        "127.0.0.1:10901"
    ]
  }
]
{{- end -}}
{{- else -}}
{{- if (typeIs "string" .Values.receive.config) }}
{{- .Values.receive.config -}}
{{- else -}}
{{- .Values.receive.config | toPrettyJson -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return true if cert-manager required annotations for TLS signed certificates are set in the Ingress annotations
Ref: https://cert-manager.io/docs/usage/ingress/#supported-annotations
*/}}
{{- define "thanos.ingress.certManagerRequest" -}}
{{ if or (hasKey . "cert-manager.io/cluster-issuer") (hasKey . "cert-manager.io/issuer") }}
    {{- true -}}
{{- end -}}
{{- end -}}
