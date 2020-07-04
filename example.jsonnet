local kp =
  (import 'kube-prometheus/kube-prometheus.libsonnet') +
  // Uncomment the following imports to enable its patches
  // (import 'kube-prometheus/kube-prometheus-anti-affinity.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-managed-cluster.libsonnet') +
  (import 'kube-prometheus/kube-prometheus-node-ports.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-static-etcd.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-thanos-sidecar.libsonnet') +
  // (import 'kube-prometheus/kube-prometheus-custom-metrics.libsonnet') +
  {
    _config+:: {
      namespace: 'monitoring',
      versions+:: {
      //   prometheus: 'v2.19.1',
      //   alertmanager: 'v0.21.0',
      //   kubeStateMetrics: '1.9.6',
        kubeRbacProxy: 'v0.5.0',
      //   addonResizer: '2.3',
      //   nodeExporter: 'v0.18.1',
        prometheusOperator: 'v0.40.0',
        prometheusAdapter: 'v0.7.0',
        grafana: '7.0.3',
      //   configmapReloader: 'latest',
      //   prometheusConfigReloader: 'v0.40.0',
      //   armExporter: 'latest',
      //   smtpRelay: 'v1.0.1',
      //   elasticExporter: '1.0.4rc1',
      },
      imageRepos+:: {
      //   prometheus: 'prom/prometheus',
      //   alertmanager: 'prom/alertmanager',
      //   kubeStateMetrics: 'carlosedp/kube-state-metrics',
        kubeRbacProxy: 'carlosedp/kube-rbac-proxy',
      //   addonResizer: 'carlosedp/addon-resizer',
      //   nodeExporter: 'prom/node-exporter',
      //   prometheusOperator: 'carlosedp/prometheus-operator',
        prometheusAdapter: 'directxman12/k8s-prometheus-adapter',
      //   grafana: 'grafana/grafana',
      //   configmapReloader: 'carlosedp/configmap-reload',
      //   prometheusConfigReloader: 'carlosedp/prometheus-config-reloader',
      //   armExporter: 'carlosedp/arm_exporter',
      //   smtpRelay: 'carlosedp/docker-smtp',
      //   elasticExporter: 'carlosedp/elasticsearch-exporter',
      },
    },
    prometheus+:: {
      prometheus+: {
        spec+: {
          additionalScrapeConfigs: {
            name: 'additional-scrape-configs',
            key: 'prometheus-additional.yaml'
          },
        },
      },
    },
  };

{ ['setup/0namespace-' + name]: kp.kubePrometheus[name] for name in std.objectFields(kp.kubePrometheus) } +
{
  ['setup/prometheus-operator-' + name]: kp.prometheusOperator[name]
  for name in std.filter((function(name) name != 'serviceMonitor'), std.objectFields(kp.prometheusOperator))
} +
// serviceMonitor is separated so that it can be created after the CRDs are ready
{ 'prometheus-operator-serviceMonitor': kp.prometheusOperator.serviceMonitor } +
{ ['node-exporter-' + name]: kp.nodeExporter[name] for name in std.objectFields(kp.nodeExporter) } +
//{ ['kube-state-metrics-' + name]: kp.kubeStateMetrics[name] for name in std.objectFields(kp.kubeStateMetrics) } +
{ ['alertmanager-' + name]: kp.alertmanager[name] for name in std.objectFields(kp.alertmanager) } +
{ ['prometheus-' + name]: kp.prometheus[name] for name in std.objectFields(kp.prometheus) } +
{ ['prometheus-adapter-' + name]: kp.prometheusAdapter[name] for name in std.objectFields(kp.prometheusAdapter) } +
{ ['grafana-' + name]: kp.grafana[name] for name in std.objectFields(kp.grafana)} +


{
  "statsd-exporter-deployment.json": {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: 'statsd-exporter',
      namespace: 'monitoring',
    },
    spec: {
      replicas: 1,
      selector: {
        matchLabels: {
          app: 'statsd-exporter'
        },
      },
      template: {
        metadata: {
          labels: {
            app: 'statsd-exporter',
          },
        },
        spec: {
          containers: [
            {
              name: 'statsd-exporter',
              image: 'registry.hub.docker.com/prom/statsd-exporter-linux-arm64:v0.17.0',
              imagePullPolicy: 'Always',
              ports: [
                {
                  containerPort: 9102,
                },
                {
                  containerPort: 9125,
                },
              ],
              args: [],
            },
          ],
        },
      },
    },
  }
} +


{
  "statsd-exporter-service.json": {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'statsd-exporter-svc',
      namespace: 'monitoring',
      labels: {
        app: 'statsd-exporter',
      },
    },
    spec: {
      ports: [
        {
          name: 'send-tcp',
          port: 9125,
          protocol: 'TCP',
          targetPort: 9125,
        },
        {
          name: 'metrics',
          port: 9102,
          protocol: 'TCP',
          targetPort: 9102,
        },
      ],
      selector: {
        app: 'statsd-exporter',
      },
    },
  }
}

