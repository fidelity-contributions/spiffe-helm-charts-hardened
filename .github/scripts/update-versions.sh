#!/usr/bin/env bash

SCRIPT="$(readlink -f "$0")"
SCRIPTPATH="$(dirname "${SCRIPT}")"

CHARTJSON="${SCRIPTPATH}/../tests/charts.json"

jq -r ".[].name" "${CHARTJSON}" | while read -r CHART; do
  ENTRYQUERY='.[] | select(.name == "'$CHART'")'
  REPO_URL="$(jq -r "$ENTRYQUERY | .repo" "${CHARTJSON}")"
  VERSION="$(jq -r "$ENTRYQUERY | .version" "${CHARTJSON}")"
  echo Processing: "${CHART}"
  echo "  repo: ${REPO_URL}"
  echo "  current version: ${VERSION}"
  helm repo add "${CHART}" "${REPO_URL}" > /dev/null
  helm repo update "${CHART}" > /dev/null
  LATEST_VERSION=$(helm search repo --regexp "${CHART}/${CHART}\v" -o json | jq -r '.[0].version')
  echo "  latest version: ${LATEST_VERSION}"
  if [ "x${VERSION}" != "x${LATEST_VERSION}" ]; then
    echo "  New version found!"
    jq "(${ENTRYQUERY}).version |= \"${LATEST_VERSION}\"" "${CHARTJSON}" > /tmp/$$
    mv /tmp/$$ "${CHARTJSON}"
  fi
done

CHARTJSON="${SCRIPTPATH}/../tests/oci-charts.json"

jq -r ".[].name" "${CHARTJSON}" | while read -r NAME; do
  ENTRYQUERY='.[] | select(.name == "'$NAME'")'
  REGISTRY="$(jq -r "$ENTRYQUERY | .registry" "${CHARTJSON}")"
  VERSION="$(jq -r "$ENTRYQUERY | .version" "${CHARTJSON}")"
  echo Processing: "${NAME}"
  echo "  chart: ${REGISTRY}"
  echo "  current version: ${VERSION}"
  LATEST_VERSION=$(crane ls "$REGISTRY" | grep 'v\?[0-9]*\.[0-9]*\.[0-9]\.*$' | sort -V -r | head -n 1)
  echo "  latest version: ${LATEST_VERSION}"
  if [ "x${VERSION}" != "x${LATEST_VERSION}" ]; then
    echo "  New version found!"
    jq "(${ENTRYQUERY}).version |= \"${LATEST_VERSION}\"" "${CHARTJSON}" > /tmp/$$
    mv /tmp/$$ "${CHARTJSON}"
  fi
done
