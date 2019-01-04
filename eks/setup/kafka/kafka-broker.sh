#!/bin/bash
SDIR=$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIGDIR=$(dirname "${SDIR}")/config
source ${CONFIGDIR}/env.sh

# printout yaml for kafka broker sts and headless service
# it is a copy of 20dns.yml and 50kafka.yml
# from https://github.com/Yolean/kubernetes-kafka/tree/v4.3.1/kafka
function printKafkaBrokerYaml {
  local maxCount=$((${KAFKA_COUNT} - 1))
  local svcELBs="${EXTERNAL_KAFKA_0_HOST}:${EXTERNAL_KAFKA_0_PORT}"
  for n in $(seq 1 ${maxCount}); do
    local host_env=EXTERNAL_KAFKA_${n}_HOST
    local port_env=EXTERNAL_KAFKA_${n}_PORT
    svcELBs="${svcELBs} ${!host_env}:${!port_env}"
  done

  echo "
apiVersion: v1
kind: Service
metadata:
  name: broker
  namespace: kafka
spec:
  ports:
  - port: 9092
  # [podname].broker.kafka.svc.cluster.local
  clusterIP: None
  selector:
    app: kafka
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: kafka
  namespace: kafka
spec:
  selector:
    matchLabels:
      app: kafka
  serviceName: \"broker\"
  replicas: ${KAFKA_COUNT}
  updateStrategy:
    type: OnDelete
  template:
    metadata:
      labels:
        app: kafka
      annotations:
    spec:
      terminationGracePeriodSeconds: 30
      initContainers:
      - name: init-config
        image: solsson/kafka-initutils@sha256:18bf01c2c756b550103a99b3c14f741acccea106072cd37155c6d24be4edd6e2
        env:
        - name: KAFKA_ELBS
          value: '${svcELBs}'
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        command: ['/bin/bash', '/etc/kafka-configmap/init.sh']
        volumeMounts:
        - name: configmap
          mountPath: /etc/kafka-configmap
        - name: config
          mountPath: /etc/kafka
      containers:
      - name: broker
        image: solsson/kafka:1.0.2@sha256:7fdb326994bcde133c777d888d06863b7c1a0e80f043582816715d76643ab789
        env:
        - name: KAFKA_LOG4J_OPTS
          value: -Dlog4j.configuration=file:/etc/kafka/log4j.properties
        - name: JMX_PORT
          value: \"5555\"
        ports:
        - name: inside
          containerPort: 9092
        - name: outside
          containerPort: 9094
        - name: jmx
          containerPort: 5555
        command:
        - ./bin/kafka-server-start.sh
        - /etc/kafka/server.properties
        lifecycle:
          preStop:
            exec:
             command: [\"sh\", \"-ce\", \"kill -s TERM 1; while $(kill -0 1 2>/dev/null); do sleep 1; done\"]
        resources:
          requests:
            cpu: 100m
            memory: 512Mi
        readinessProbe:
          tcpSocket:
            port: 9092
          timeoutSeconds: 1
        volumeMounts:
        - name: config
          mountPath: /etc/kafka
        - name: data
          mountPath: /var/lib/kafka/data
      volumes:
      - name: configmap
        configMap:
          name: broker-config
      - name: config
        emptyDir: {}
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ \"ReadWriteOnce\" ]
      storageClassName: kafka-broker
      resources:
        requests:
          storage: 10Gi"
}

function startKafkaBrokers {
  printKafkaBrokerYaml > ${SDIR}/50kafka.yml
  kubectl apply -f ${SDIR}/50kafka.yml
}

# startKafkaBrokers

