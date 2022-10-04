#!/usr/bin/env bash
set -e

INPUT_USERNAME="${INPUT_USERNAME:-$1}"

INPUT_DATAFILE="${INPUT_DATAFILE:-$2}"
INPUT_DATAFILE="${INPUT_DATAFILE:-credly-badges.json}"
INPUT_DATAFILE="${GITHUB_WORKSPACE}/data/${INPUT_DATAFILE}"
mkdir -p "$(dirname ${INPUT_DATAFILE})"
rm -f "${INPUT_DATAFILE}"

INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-$3}"
INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-assets/images/credly-badges}"
INPUT_IMAGEDIR="${GITHUB_WORKSPACE}/${INPUT_IMAGEDIR}/"
mkdir -p "${INPUT_IMAGEDIR}"

curl --silent "https://www.credly.com/users/${INPUT_USERNAME}/badges.json" \
    | jq --sort-keys '
        .data 
        | map({
            "description": .badge_template.description,
            "expires_at": .expires_at_date?, 
            "id": .id, 
            "image_url": .badge_template.image_url, 
            "issued_at": .issued_at_date, 
            "issuer_url": .badge_template.global_activity_url,             
            "microsoft_ids": 
                [.badge_template.badge_template_activities[] | .url] 
                | del(..|nulls) 
                | [.[] | split("/") | .[-1] | ascii_upcase ],
            "name": .badge_template.name, 
            "url": ("https://www.credly.com/badges/" + .id)
        }) 
        | sort_by(.issued_at)' \
    > "${INPUT_DATAFILE}"

for line in $(jq --raw-output '.[] | (.image_url + "," + .id)' ${INPUT_DATAFILE}); do
    IFS=, read url id <<< $line

    outputFile="${INPUT_IMAGEDIR}/${id}.${url##*.}"
    if [ ! -f $outputFile ]; then
        curl --silent "${url}" > $outputFile
    fi
done