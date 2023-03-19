#!/bin/bash

#kubesec-scan.sh

# using kubesec v2 api
scan_result=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan)
scan_message=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].message -r )
scan_score=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan | jq .[0].score)

echo $scan_score

if [[ "${scan_score}" -ge 4 ]]; then
  echo "Score is $scan_score"
  echo "Kubesec Scan $scan_message"
else
  echo "Score is $scan_score"
  echo "Kubernetes template scanning failed because score is less than or equal to $scan_score"
  exit 1;
fi
