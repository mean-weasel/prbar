#!/usr/bin/env bash
set -euo pipefail

PROFILE="${IOS_UI_SMOKE_PROFILE:-}"
case "$PROFILE" in
  growth|full|live|production) ;;
  *)
    echo "Skipping PostHog dashboard preflight for IOS_UI_SMOKE_PROFILE=${PROFILE:-unset}."
    exit 0
    ;;
esac

for name in \
  PRBAR_IOS_POSTHOG_HOST \
  PRBAR_IOS_POSTHOG_PROJECT_ID \
  PRBAR_IOS_POSTHOG_PERSONAL_API_KEY \
  PRBAR_IOS_POSTHOG_DASHBOARD_ID; do
  if [[ -z "${!name:-}" ]]; then
    echo "$name is required for IOS_UI_SMOKE_PROFILE=$PROFILE." >&2
    exit 1
  fi
done

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  echo "::add-mask::$PRBAR_IOS_POSTHOG_PERSONAL_API_KEY"
fi

HOST="${PRBAR_IOS_POSTHOG_HOST%/}"
PROJECT_ID="$PRBAR_IOS_POSTHOG_PROJECT_ID"
DASHBOARD_ID="$PRBAR_IOS_POSTHOG_DASHBOARD_ID"

dashboard_url="$HOST/api/environments/$PROJECT_ID/dashboards/$DASHBOARD_ID/"
run_insights_url="$HOST/api/environments/$PROJECT_ID/dashboards/$DASHBOARD_ID/run_insights/?output_format=json&refresh=blocking"

probe() {
  local label="$1"
  local url="$2"
  local body_file
  local status

  body_file="$(mktemp "${TMPDIR:-/tmp}/prbar-posthog-preflight.XXXXXX")"
  if ! status="$(
    curl \
      --silent \
      --show-error \
      --location \
      --connect-timeout 10 \
      --max-time 60 \
      --output "$body_file" \
      --write-out "%{http_code}" \
      --header "Accept: application/json" \
      --header "Authorization: Bearer $PRBAR_IOS_POSTHOG_PERSONAL_API_KEY" \
      "$url"
  )"; then
    echo "PostHog $label preflight failed before receiving an HTTP response." >&2
    rm -f "$body_file"
    exit 1
  fi

  if [[ "$status" =~ ^2[0-9][0-9]$ ]]; then
    echo "PostHog $label preflight passed with HTTP $status."
    rm -f "$body_file"
    return 0
  fi

  echo "PostHog $label preflight failed with HTTP $status." >&2
  case "$status" in
    401|403)
      echo "The configured personal API key cannot read the $label endpoint for project $PROJECT_ID and dashboard $DASHBOARD_ID." >&2
      echo "Verify the key belongs to a PostHog user with access to this project and includes the read scopes required by dashboards, insights, and dashboard query execution." >&2
      ;;
    404)
      echo "Verify PRBAR_IOS_POSTHOG_PROJECT_ID=$PROJECT_ID and PRBAR_IOS_POSTHOG_DASHBOARD_ID=$DASHBOARD_ID point to the same PostHog project." >&2
      ;;
  esac

  if [[ -s "$body_file" ]]; then
    echo "PostHog response excerpt:" >&2
    tr '\n' ' ' < "$body_file" | head -c 800 >&2
    echo >&2
  fi

  rm -f "$body_file"
  exit 1
}

probe "dashboard metadata" "$dashboard_url"
probe "dashboard run_insights" "$run_insights_url"
