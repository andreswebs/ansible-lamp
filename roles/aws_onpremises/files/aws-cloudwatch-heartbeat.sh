#!/bin/bash

NAMESPACE="OnPremises/heartbeat"

METRIC_DATA="MetricName=heartbeat,Dimensions=[{Name=Hosts,Value=${HOSTNAME}}],Value=1"

aws cloudwatch put-metric-data --namespace "${NAMESPACE}" --metric-data "${METRIC_DATA}"
