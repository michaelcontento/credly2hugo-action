#!/usr/bin/env sh
set -e

USERNAME="${1}"
DATAFILE="${GITHUB_WORKSPACE}/data/${2}"

mkdir -p "$(dirname ${DATAFILE})"
rm -f "${DATAFILE}"

curl --silent "https://www.credly.com/users/${USERNAME}/badges.json" \
    | jq --sort-keys '.data | map({"expires_at": .expires_at_date?, "issued_at": .issued_at_date, "description": .badge_template.description, "name": .badge_template.name, "image_url": .badge_template.image_url, "issuer_url": .badge_template.global_activity_url, "url": ("https://www.credly.com/badges/" + .id), "id": [.badge_template.badge_template_activities[] | .url] | del(..|nulls) | .[0] | split("/") | .[-1] | ascii_upcase}) | sort_by(.issued_at)' \
    > "${DATAFILE}"
