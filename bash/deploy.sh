#!/bin/bash

if [[ "$1" = "" ]] || [[ "$2" = "" ]] || [[ "$3" = "" ]] || [[ "$4" = "" ]]
then
    echo "Format: ./deploy [replicaCount] [testback/backendVersion] [hs/holySheetVersion] [domain] <credentials file>"
    exit
fi

if [[ "$5" = "true" ]]
then
  echo "Creating credentials file from \"$5\""
  kubectl create secret generic google-credentials --from-file=$5
fi

exit

echo "Using images rubbaboy/testback:$2 and rubbaboy/hs:$3"

cat <<EOT >> kubernetes.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hs-backend
spec:
  replicas: $1
  selector:
    matchLabels:
      app: hs-backend
  template:
    metadata:
      labels:
        app: hs-backend
    spec:
      nodeSelector:
        "beta.kubernetes.io/os": linux
      volumes:
        - name: processing
          emptyDir: {}
      containers:
        - name: api
          image: rubbaboy/testback:$2
          volumeMounts:
            - name: processing
              mountPath: /tmp/processing
          ports:
            - containerPort: 80
          env:
            - name: PORT
              value: '80'
            - name: GRPC
              value: '8888'
            - name: ALLOW_ORIGIN
              value: '$4'
            - name: PROCESSING_PATH
              value: '/tmp/processing'
        - name: core
          image: rubbaboy/hs:$3
          volumeMounts:
            - name: processing
              mountPath: /tmp/processing
          env:
            - name: CLIENT_SECRET
              valueFrom:
                secretKeyRef:
                  name: google-credentials
                  key: credentials.json
---
apiVersion: v1
kind: Service
metadata:
  name: hs-backend
spec:
  type: LoadBalancer
  sessionAffinity: ClientIP
  ports:
    - port: 80
  selector:
    app: hs-backend
EOT

echo "Applying to kubernetes..."

kubectl apply -f kubernetes.yml

echo "To change arguments, run the following command with your prefered arguments:"
echo "./deploy $1 $2 $3 $4"
