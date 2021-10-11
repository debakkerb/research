# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

---
# Source: td-autoinject/templates/poddisruptionbudget.yaml
# yamllint disable
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: istio-sidecar-injector
  namespace: istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
    istio: sidecar-injector
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: sidecar-injector
      release: istio-control-istio-autoinject
      istio: sidecar-injector

---
# Source: td-autoinject/templates/sidecar-injector-configmap.yaml
# yamllint disable
apiVersion: v1
kind: ConfigMap
metadata:
  name: istio-sidecar-injector
  namespace: istio-control
  labels:
    release: istio-control-istio-autoinject
    app: sidecar-injector
    istio: sidecar-injector
data:
  values: |-
    {"clusterResources":true,"global":{"arch":{"amd64":2,"ppc64le":2,"s390x":2},"configNamespace":"istio-control","configValidation":"false","controlPlaneSecurityEnabled":true,"defaultNodeSelector":{},"defaultPodDisruptionBudget":{"enabled":true},"defaultResources":{"requests":{"cpu":"10m"}},"disablePolicyChecks":true,"enableHelmTest":false,"enableTracing":true,"hub":"istio","imagePullPolicy":"Always","imagePullSecrets":[],"istioNamespace":"istio-control","k8sIngress":{"enableHttps":false,"enabled":false,"gatewayName":"ingressgateway"},"localityLbSetting":{"enabled":true},"logAsJson":false,"logging":{"level":"default:info"},"meshExpansion":{"enabled":false,"useILB":false},"meshID":"","meshNetworks":{},"mtls":{"enabled":false},"multiCluster":{"enabled":false},"oneNamespace":false,"outboundTrafficPolicy":{"mode":"ALLOW_ANY"},"policyCheckFailOpen":false,"policyNamespace":"istio-system","priorityClassName":"","prometheusNamespace":"istio-system","proxy":{"accessLogEncoding":"TEXT","accessLogFile":"","accessLogFormat":"","autoInject":"enabled","clusterDomain":"cluster.local","componentLogLevel":"misc:error","concurrency":2,"dnsRefreshRate":"300s","enableCoreDump":false,"envoyAccessLogService":{"enabled":false,"host":null,"port":null},"envoyMetricsService":{"enabled":false,"host":null,"port":null},"envoyStatsd":{"enabled":false,"host":null,"port":null},"excludeIPRanges":"","excludeInboundPorts":"","excludeOutboundPorts":"","image":"proxyv2","includeIPRanges":"*","includeInboundPorts":"*","kubevirtInterfaces":"","logLevel":"warning","privileged":false,"protocolDetectionTimeout":"10ms","readinessFailureThreshold":30,"readinessInitialDelaySeconds":1,"readinessPeriodSeconds":2,"resources":{"limits":{"cpu":"2000m","memory":"1024Mi"},"requests":{"cpu":"100m","memory":"128Mi"}},"statusPort":15020,"tag":"1.7.0","tracer":"zipkin"},"proxy_init":{"image":"proxyv2","resources":{"limits":{"cpu":"100m","memory":"50Mi"},"requests":{"cpu":"10m","memory":"10Mi"}}},"sds":{"enabled":false,"udsPath":""},"tag":"1.5.8","telemetryNamespace":"istio-system","tracer":{"datadog":{"address":"$(HOST_IP):8126"},"lightstep":{"accessToken":"","address":"","cacertPath":"","secure":true},"zipkin":{"address":""}},"trustDomain":"","useMCP":true,"xdsApiVersion":"v3"},"istio_cni":{"enabled":false},"sidecarInjectorWebhook":{"alwaysInjectSelector":[],"enableAccessLog":false,"enableNamespacesByDefault":false,"image":"sidecar_injector","injectLabel":"istio-injection","neverInjectSelector":[],"nodeSelector":{},"podAntiAffinityLabelSelector":[],"podAntiAffinityTermLabelSelector":[],"replicaCount":2,"rewriteAppHTTPProbe":false,"rollingMaxSurge":"100%","rollingMaxUnavailable":"25%","selfSigned":true,"tolerations":[]},"version":""}

  config: |-
    policy: enabled
    alwaysInjectSelector:
      []

    neverInjectSelector:
      []

    template: |
      containers:
      - name: envoy
        image: envoyproxy/envoy:v1.18.3
        imagePullPolicy: Always
        resources:
          limits:
            cpu: "2"
            memory: 1Gi
          requests:
            cpu: 100m
            memory: 128Mi
        env:
        - name: ENVOY_UID
          value: "1337"
        volumeMounts:
        - mountPath: /etc/envoy
          name: envoy-bootstrap
        {{- if eq (annotation .ObjectMeta `cloud.google.com/enableManagedCerts` `false`) `true` }}
        - mountPath: /var/run/secrets/workload-spiffe-credentials
          name: gke-workload-certificates
          readOnly: true
        {{- end }}
      initContainers:
      - name: td-bootstrap-writer
        image: gcr.io/trafficdirector-prod/xds-client-bootstrap-generator
        imagePullPolicy: Always
        args:
          - --project_number={{.ProxyConfig.ProxyMetadata.TRAFFICDIRECTOR_GCP_PROJECT_NUMBER}}
          - --network_name={{.ProxyConfig.ProxyMetadata.TRAFFICDIRECTOR_NETWORK_NAME}}
          - --bootstrap_file_output_path=/var/lib/data/envoy.yaml
          - --traffic_director_url=trafficdirector.googleapis.com:443
          {{- if (isset .ObjectMeta.Annotations `cloud.google.com/includeInboundPorts`) }}
          - --inbound_backend_ports={{ (annotation .ObjectMeta `cloud.google.com/includeInboundPorts` ``) }}
          {{- end }}
          {{- if eq (annotation .ObjectMeta `cloud.google.com/forwardPodLabels` `false`) `true` }}
          - --proxy_metadata={{ toJSON .ObjectMeta.Labels }}
          {{- else if (isset .ObjectMeta.Annotations `cloud.google.com/proxyMetadata`) }}
          - |
              --proxy_metadata={{ (annotation .ObjectMeta `cloud.google.com/proxyMetadata` `{}`) }}
          {{- end }}
          {{- if eq (annotation .ObjectMeta `cloud.google.com/enableManagedCerts` `false`) `true` }}
          - --use_workload_certificates
          {{- end }}
          {{- if isset .ProxyConfig.ProxyMetadata `TRAFFICDIRECTOR_ACCESS_LOG_PATH` }}
          - --access_log_path={{.ProxyConfig.ProxyMetadata.TRAFFICDIRECTOR_ACCESS_LOG_PATH}}
          {{- end }}
          {{- if eq (valueOrDefault .ProxyConfig.ProxyMetadata.TRAFFICDIRECTOR_ENABLE_TRACING "") "true" }}
          - --enable_tracing
          {{- end }}
          - --envoy_admin_port={{.ProxyConfig.ProxyAdminPort}}
          {{- if isset .ProxyConfig.ProxyMetadata `PROXY_STATS_PORT` }}
          - --expose_stats_port={{.ProxyConfig.ProxyMetadata.PROXY_STATS_PORT}}
          {{- end }}
        volumeMounts:
          - mountPath: /var/lib/data
            name: envoy-bootstrap
      - name: istio-init
        image: istio/proxyv2:1.7.0
        imagePullPolicy: IfNotPresent
        args:
          - istio-iptables
          - -p
          - "15001"
          - -u
          - "1337"
          - -m
          - REDIRECT
          - -i
          - "{{ (annotation .ObjectMeta `cloud.google.com/includeOutboundCIDRs` `*`) }}"
          - -b
          - "{{ (annotation .ObjectMeta `cloud.google.com/includeInboundPorts` ``) }}"
          - -x
          - "{{ (annotation .ObjectMeta `cloud.google.com/excludeOutboundCIDRs` `169.254.169.254/32`) }}"
          - -d
          - "{{ (annotation .ObjectMeta `cloud.google.com/excludeInboundPorts` ``) }}"
          - -o
          - "{{ (annotation .ObjectMeta `cloud.google.com/excludeOutboundPorts` ``) }}"
        resources:
          limits:
            cpu: 100m
            memory: 50Mi
          requests:
            cpu: 10m
            memory: 10Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
            drop:
            - ALL
          privileged: false
          readOnlyRootFilesystem: false
          runAsGroup: 0
          runAsNonRoot: false
          runAsUser: 0
      volumes:
        - name: envoy-bootstrap
          emptyDir: {}
        {{- if eq (annotation .ObjectMeta `cloud.google.com/enableManagedCerts` `false`) `true` }}
        - name: gke-workload-certificates
          csi:
            driver: workloadcertificates.security.cloud.google.com
        {{- end }}
    ---



---
# Source: td-autoinject/templates/serviceaccount.yaml
# yamllint disable
apiVersion: v1
kind: ServiceAccount
metadata:
  name: istio-sidecar-injector-service-account
  namespace: istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
    istio: sidecar-injector

---
# Source: td-autoinject/templates/clusterrole.yaml
# yamllint disable
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: istio-sidecar-injector-istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
    istio: sidecar-injector
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["istio-sidecar-injector"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["admissionregistration.k8s.io"]
  resources: ["mutatingwebhookconfigurations"]
  resourceNames: ["istio-sidecar-injector", "istio-sidecar-injector-istio-control"]
  verbs: ["get", "list", "watch", "patch"]

---
# Source: td-autoinject/templates/clusterrolebinding.yaml
# yamllint disable
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: istio-sidecar-injector-admin-role-binding-istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
    istio: sidecar-injector
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: istio-sidecar-injector-istio-control
subjects:
  - kind: ServiceAccount
    name: istio-sidecar-injector-service-account
    namespace: istio-control

---
# Source: td-autoinject/templates/service.yaml
# yamllint disable
apiVersion: v1
kind: Service
metadata:
  name: istio-sidecar-injector
  namespace: istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
    istio: sidecar-injector
spec:
  ports:
  - port: 443
    targetPort: 9443
  selector:
    istio: sidecar-injector

---
# Source: td-autoinject/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: istio-sidecar-injector
  namespace: istio-control
  labels:
    app: sidecarInjectorWebhook
    release: istio-control-istio-autoinject
    istio: sidecar-injector
spec:
  replicas: 2
  selector:
    matchLabels:
      istio: sidecar-injector
  strategy:
    rollingUpdate:
      maxSurge: 100%
      maxUnavailable: 25%
  template:
    metadata:
      labels:
        app: sidecarInjectorWebhook
        istio: sidecar-injector
      annotations:
        sidecar.istio.io/inject: "false"
    spec:
      serviceAccountName: istio-sidecar-injector-service-account
      containers:
        - name: sidecar-injector-webhook
          image: "istio/sidecar_injector:1.5.8"
          imagePullPolicy: Always
          args:
            - --caCertFile=/etc/istio/certs/ca-cert.pem
            - --tlsCertFile=/etc/istio/certs/cert.pem
            - --tlsKeyFile=/etc/istio/certs/key.pem
            - --injectConfig=/etc/istio/inject/config
            - --meshConfig=/etc/istio/config/mesh
            - --port=9443
            - --healthCheckInterval=2s
            - --healthCheckFile=/tmp/health
            - --reconcileWebhookConfig=true
            - --webhookConfigName=istio-sidecar-injector-istio-control
            - --log_output_level=debug



          volumeMounts:
          - name: config-volume
            mountPath: /etc/istio/config
            readOnly: true
          - name: certs
            mountPath: /etc/istio/certs
            readOnly: true
          - name: inject-config
            mountPath: /etc/istio/inject
            readOnly: true
          livenessProbe:
            exec:
              command:
                - /usr/local/bin/sidecar-injector
                - probe
                - --probe-path=/tmp/health
                - --interval=4s
            initialDelaySeconds: 4
            periodSeconds: 4
          readinessProbe:
            exec:
              command:
                - /usr/local/bin/sidecar-injector
                - probe
                - --probe-path=/tmp/health
                - --interval=4s
            initialDelaySeconds: 4
            periodSeconds: 4
          resources:
            requests:
              cpu: 10m

      volumes:
      - name: config-volume
        configMap:
          name: injector-mesh
      - name: certs
        secret:
          secretName: istio-sidecar-injector
      - name: inject-config
        configMap:
          name: istio-sidecar-injector
          items:
          - key: config
            path: config
          - key: values
            path: values
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - amd64
                - ppc64le
                - s390x
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 2
            preference:
              matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - amd64
          - weight: 2
            preference:
              matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - ppc64le
          - weight: 2
            preference:
              matchExpressions:
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - s390x

---
# Source: td-autoinject/templates/mutatingwebhook.yaml
# yamllint disable
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: istio-sidecar-injector-istio-control
  labels:
    app: sidecar-injector
    release: istio-control-istio-autoinject
webhooks:
  - name: sidecar-injector.istio.io
    sideEffects: None
    admissionReviewVersions: ["v1beta1"]
    clientConfig:
      service:
        name: istio-sidecar-injector
        namespace: istio-control
        path: "/inject"
      caBundle: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUZmakNDQTJhZ0F3SUJBZ0lVT0Jva0s4dnpEU205N3ZsTUUxWjI3RVFXcE0wd0RRWUpLb1pJaHZjTkFRRUwKQlFBd016RXhNQzhHQTFVRUF3d29hWE4wYVc4dGMybGtaV05oY2kxcGJtcGxZM1J2Y2k1cGMzUnBieTFqYjI1MApjbTlzTG5OMll6QWVGdzB5TVRFd01UQXhNREE1TXpOYUZ3MHlNakV3TVRBeE1EQTVNek5hTURNeE1UQXZCZ05WCkJBTU1LR2x6ZEdsdkxYTnBaR1ZqWVhJdGFXNXFaV04wYjNJdWFYTjBhVzh0WTI5dWRISnZiQzV6ZG1Nd2dnSWkKTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUtBb0lDQVFESDZIUVI2bzg1YzNpWXdVOEtUcVE2TElHUgo2TkN2NlVLaGtzaHpjL2cxUEVXMzBnVEpoK0lCb2hkYldrMElBMmdHRXd6a2VGcnc1bTZ1TTlrUHVrYWFhdmVQCmVHc0NQS25MMFlUWTA0aGFMSGMwWnM1VWFzOGtncUU2a1FhQUtQMjI5aURpUm9vN1dhK1k3T1dKdzRPbUNseWMKRWVsam1oQXhpN01RcW1vVWFHVVhyMDFBOGl3cHZJNXAxckI5bVRWdHBCU3FOY3NNckVJZi9JZjVXamN3SFBPZwpVMU1ickxnZFBPUDdlNWhXT1pCTVRCVjJFLy9VbUozZjg5QlQ2SVZwYWVTMUpiSW5OODQxRnRJRzM5RWFyRVpsCnI2SUxtYjlzVkZob0J2aHdUWUxJSlYzQldpYXBBNzVTanQwOVN3dVZZM3VmVytidThKZGgwTGJ5WEtVaWFGWDQKMkFDUmw5eVhkaEN4VmNqdklWZlRMRkRqTzhtN25saFJuVlpWZ1BxQjlUd2dESkpoUFpabmxEeTZUa0UwRGMrcApEREFEc2dZYlpEV3BjaStYWFF0UDU3SGNWcE5naEtSM0JFRXU4MUxiSXpaV1U0bTdEbjQwSkJiaXR4UG9ieHV5ClN1K2ZKVVZJRDN1Q05zVUJGU0ZMUmgwOVhaVlVlQTFjdHFpMGZRc1Y4OFhLQnoxNlE4VURMOXVSU1VmcHVjVk4KTGx1MmU5R0NzYzN0KzRyWndMcWRGeEtrVXVYaU9hU1dIRlVoSnZGTjF4SzVXdmxlK2ZiMXBlbnVmeXkxK3NGZgpQcm53KytZYWNpRDEzTXpkL1dYclZ2U2dQRFJIT1ZVdWk5aEJLR1BRcGIxcDAwTklOZnBqZ3ZmMTdDTjdCY3ZDCkNlelNVYnAxUTNPQzVodmdzd0lEQVFBQm80R0pNSUdHTUIwR0ExVWREZ1FXQkJUWTI0bUswUDh0dGlhR3NmTVEKM0M3NW9XTWZwREFmQmdOVkhTTUVHREFXZ0JUWTI0bUswUDh0dGlhR3NmTVEzQzc1b1dNZnBEQVBCZ05WSFJNQgpBZjhFQlRBREFRSC9NRE1HQTFVZEVRUXNNQ3FDS0dsemRHbHZMWE5wWkdWallYSXRhVzVxWldOMGIzSXVhWE4wCmFXOHRZMjl1ZEhKdmJDNXpkbU13RFFZSktvWklodmNOQVFFTEJRQURnZ0lCQUVoTGR4N1NzTHpHVHh2VlUwV2EKZkU1alA2UFBkSEticGt2WXFCUFFvZHlPVGkya2FSaHd1YzV4eGc0cnNIaWl5bXFRNHZIbU1Kbm9abEdkZ3FsdQozb3hLWTEzYWl2UHRSMEIxb2tvMzZaSTUxMjAycU0wWHVCNHcxNEpYeWFTbTFvRXcyUk5zUTRmaUQ2U2NzODh0CmdlbmZRekgvNk1lMUx5QUF5bHkzMEJOdEpEYzMrRFhhV3B4UENOVEVRQ0IrR2thM1d0R1RrZ1BuVUZUQnFCajIKbUxzZTJucnE5em1pOGl5eGY4bVZGRzg3cDBqdko4RGtDbWYvWWpIalZJTFpDTE9WL0ozVkZoam1JSzR5eGZ2TApuMVNsUUxrT2NFTTNHdUw3akhJQ2RDalJqYXpOdXNlek0rS3VGNExhTVpPMVNac2xZYkhKSmFacmczSm9ndXVpCndPZC9HeGxOUzJFajFEQVhDZkxCQXpaeXVma3AxTHg2NXloVjBodEYzbFgwZkJNOG9xYVRNekViQkd5L0NVN2cKbEZlVHh1ZzhxN05kVjQ3eHBZUUY2cGJZQUVUWjROckJqdUxFRDN3ajlUOHdUMnBIZkI5TktZdnZzQzZQREE2WQpyalRIR1ZkWnVOM1dqYlNOYkxHWjk4QkRWWlNVTWxKbUw5cjdqWWIwYm8vSzZVWDJ4S0VtZ2R6SVRnSEFMZjY2CkRKd21tSFNBbEFGclQ4WUsyRDNmWExURHFsQlVOZi9oQktEdlpkRzZGMm1qQ3IwVVNxYXloZmlrQW5VelhmV0EKSE5EbEJxN2svS2hjN21RbW9YcksxWWI2dFZSSkV5b0V5bzluWVZWbWRCMUs2SkpnbXZpNjVmMnBNTGtKNWhacAp4ME1aeUpETm5BTjFwR2xGMzlMd0tybCsKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    rules:
      - operations: [ "CREATE" ]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
    failurePolicy: Fail
    namespaceSelector:
      matchLabels:
        istio-injection: enabled
---