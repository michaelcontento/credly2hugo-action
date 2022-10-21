#!/usr/bin/env bash
set -e

INPUT_USERNAME="${INPUT_USERNAME:-$1}"
echo "::debug::Credly username: ${INPUT_USERNAME}"

INPUT_DATAFILE="${INPUT_DATAFILE:-$2}"
INPUT_DATAFILE="${INPUT_DATAFILE:-CredlyBadges.json}"
INPUT_DATAFILE="${GITHUB_WORKSPACE}/data/${INPUT_DATAFILE}"
mkdir -p "$(dirname "$INPUT_DATAFILE")"
rm -f "$INPUT_DATAFILE"
echo "::debug::Storage location for badge json file: $INPUT_DATAFILE"

INPUT_DATAFILERAW="${INPUT_DATAFILE//.json/Raw.json}"
rm -f "$INPUT_DATAFILERAW"
echo "::debug::Storage location for raw badge json file: $INPUT_DATAFILERAW"

INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-$3}"
INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-images/CredlyBadges}"
echo "::debug::Storage location for badge image files: assets/$INPUT_IMAGEDIR"

URL="https://www.credly.com/users/${INPUT_USERNAME}/badges.json"
echo "::debug::Credly json url: $URL"
echo "::notice::Downloading infos from Credly"
curl --silent "$URL" | jq --sort-keys '.data|=sort_by(.issued_at)' > "$INPUT_DATAFILERAW"
jq --sort-keys \
    '
        .data
        | map({
            "CredlyUrl": ("https://www.credly.com/badges/" + .id),
            "Description": .badge_template.description,
            "ExpiresAt": .expires_at_date?,
            "Id": .id,
            "IssuedAt": .issued_at_date,
            "IssuerUrl": .badge_template.global_activity_url,
            "LocalImagePath": (
                "'"${INPUT_IMAGEDIR}"'"
                + "/"
                + .id
                + "."
                + (.badge_template.image_url | split(".") | .[-1])
            ),
            "MicrosoftIds":
                (if
                    .issuer.entities[0].entity.name == "Microsoft"
                then
                    [.badge_template.badge_template_activities[] | .url]
                    | del(..|nulls)
                    | [.[] | split("/") | .[-1] | ascii_upcase ]
                else
                    null
                end),
            "Name": .badge_template.name,
            "RemoteImageUrl": .badge_template.image_url
        })
        | sort_by(.issued_at)
    ' \
    "$INPUT_DATAFILERAW" \
    > "$INPUT_DATAFILE"

BADGED_FOUND=$(jq '.[] | .id' "$INPUT_DATAFILE" | wc -l)
echo "::notice::Found $BADGED_FOUND badges on Credly"

for line in $(jq --raw-output '.[] | (.Id + "," + .RemoteImageUrl + "," + .LocalImagePath)' "$INPUT_DATAFILE"); do
    IFS=, read -r id remoteUrl localPath <<< "$line"
    FULL_LOCAL_PATH="${GITHUB_WORKSPACE}/assets/${localPath}"

    if [ -f "$FULL_LOCAL_PATH" ]; then
        echo "::notice::Badge image for id $id already present - skipping download"
    else
        echo "::notice::Downloading bage image for id $id"
        mkdir -p "$(dirname "$FULL_LOCAL_PATH")"
        curl --silent "$remoteUrl" > "$FULL_LOCAL_PATH"
    fi
done