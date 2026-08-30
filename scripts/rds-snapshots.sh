#!/usr/bin/env bash

set -euo pipefail

region="${AWS_REGION:-us-east-1}"
services=(customer account transaction)

usage() {
  echo "Usage: $0 resolve <dev|prod>"
  echo "       $0 prune <dev|prod> <snapshot-suffix>"
}

validate_environment() {
  case "$1" in
    dev | prod) ;;
    *)
      echo "Environment must be dev or prod." >&2
      exit 1
      ;;
  esac
}

load_snapshots() {
  aws rds describe-db-snapshots \
    --snapshot-type manual \
    --region "${region}" \
    --output json
}

resolve_snapshot_set() {
  local environment="$1"
  local snapshots
  local matching_count
  local result

  snapshots="$(load_snapshots)"

  matching_count="$(
    jq \
      --arg environment "${environment}" \
      '[
        .DBSnapshots[]
        | select(
            .DBSnapshotIdentifier
            | startswith("as-bank-\($environment)-")
          )
      ]
      | length' \
      <<< "${snapshots}"
  )"

  result="$(
    jq -c \
      --arg environment "${environment}" \
      '
      [
        .DBSnapshots[]
        | select(.Status == "available")
        | . as $snapshot
        | ["customer", "account", "transaction"][] as $service
        | "as-bank-\($environment)-\($service)-final-" as $prefix
        | select($snapshot.DBSnapshotIdentifier | startswith($prefix))
        | {
            service: $service,
            suffix: ($snapshot.DBSnapshotIdentifier | ltrimstr($prefix)),
            snapshot: $snapshot.DBSnapshotIdentifier,
            created: $snapshot.SnapshotCreateTime
          }
      ]
      | group_by(.suffix)
      | map(
          select(
            ([.[].service] | unique | length) == 3
          )
          | {
              suffix: .[0].suffix,
              created: ([.[].created] | max),
              snapshot_identifiers: (
                map({
                  key: .service,
                  value: .snapshot
                })
                | from_entries
              )
            }
        )
      | sort_by(.created)
      | last // {
          suffix: "",
          created: "",
          snapshot_identifiers: {}
        }
      ' \
      <<< "${snapshots}"
  )"

  if [[ "$(jq -r '.suffix' <<< "${result}")" == "" ]] &&
     (( matching_count > 0 )); then
    echo "Snapshots exist for ${environment}, but no complete three-service generation is available." >&2
    exit 1
  fi

  printf '%s\n' "${result}"
}

prune_snapshot_sets() {
  local environment="$1"
  local keep_suffix="$2"
  local snapshots
  local keep_count

  snapshots="$(load_snapshots)"

  keep_count="$(
    jq \
      --arg environment "${environment}" \
      --arg suffix "${keep_suffix}" \
      '[
        .DBSnapshots[]
        | select(.Status == "available")
        | .DBSnapshotIdentifier as $id
        | ["customer", "account", "transaction"][] as $service
        | select(
            $id ==
            "as-bank-\($environment)-\($service)-final-\($suffix)"
          )
      ]
      | length' \
      <<< "${snapshots}"
  )"

  if (( keep_count != 3 )); then
    echo "Refusing cleanup: generation ${keep_suffix} does not contain three available snapshots." >&2
    exit 1
  fi

  while IFS= read -r snapshot; do
    [[ -z "${snapshot}" ]] && continue

    echo "Deleting older snapshot ${snapshot}"

    aws rds delete-db-snapshot \
      --region "${region}" \
      --db-snapshot-identifier "${snapshot}" \
      >/dev/null
  done < <(
    jq -r \
      --arg environment "${environment}" \
      --arg keep_suffix "${keep_suffix}" \
      '
      .DBSnapshots[]
      | select(.Status == "available")
      | .DBSnapshotIdentifier as $id
      | ["customer", "account", "transaction"][] as $service
      | "as-bank-\($environment)-\($service)-final-" as $prefix
      | select($id | startswith($prefix))
      | select(($id | ltrimstr($prefix)) != $keep_suffix)
      | $id
      ' \
      <<< "${snapshots}" |
      sort -u
  )
}

if (( $# < 2 )); then
  usage
  exit 1
fi

command="$1"
environment="$2"

validate_environment "${environment}"

case "${command}" in
  resolve)
    if (( $# != 2 )); then
      usage
      exit 1
    fi

    resolve_snapshot_set "${environment}"
    ;;

  prune)
    if (( $# != 3 )); then
      usage
      exit 1
    fi

    prune_snapshot_sets "${environment}" "$3"
    ;;

  *)
    usage
    exit 1
    ;;
esac