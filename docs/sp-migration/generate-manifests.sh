#!/bin/sh
set -e

version_aws=v0.37.0
version_azure=v0.34.0
version_gcp=v0.34.0

rm -f "sp-manual.yaml" && touch "sp-manual.yaml"
rm -f "sp-family-manual.yaml" && touch "sp-family-manual.yaml"
kubectl get managed --no-headers -o jsonpath='{range .items[*]}{.apiVersion}{"\n"}{end}' | grep -E '(aws|gcp|azure).upbound.io' | sort | uniq | while read -r line
do
  service=$(echo "${line}" | cut -d. -f1)
  provider=$(echo "${line}" | cut -d. -f2)
  if [ "${provider}" = "upbound" ]; then
    # azure.upbound.io is an exception where apiVersion does not contain the service name
    # we have those resources in the family package
    provider="azure"
  fi
  eval version=\$"version_${provider}"

  for sp in config ${service}; do
    filename="sp-manual.yaml"
    providername="${provider}-${sp}"

    if [ "${sp}" = "config" ] || [ "${sp}" = "azure" ]; then
      # azure.upbound.io is an exception where apiVersion does not contain the service name
      # we have those resources in the family package
      providername="family-$provider"
      filename="sp-family-manual.yaml"
    fi
    if ! cat "${filename}" | grep provider-${providername}:${version} > /dev/null; then
    echo "apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: upbound-release-candidates-provider-${providername}
spec:
  package: xpkg.upbound.io/upbound-release-candidates/provider-${providername}:${version}
  revisionActivationPolicy: Manual" >> "${filename}"
    echo "---" >> "${filename}"
    fi
  done
done