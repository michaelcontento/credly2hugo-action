#!/usr/bin/env bash
set -e

INPUT_USERNAME="${INPUT_USERNAME:-$1}"
echo "::debug username=${INPUT_USERNAME}::Credly username"

INPUT_DATAFILE="${INPUT_DATAFILE:-$2}"
INPUT_DATAFILE="${INPUT_DATAFILE:-credly-badges.json}"
INPUT_DATAFILE="${GITHUB_WORKSPACE}/data/${INPUT_DATAFILE}"
mkdir -p "$(dirname ${INPUT_DATAFILE})"
rm -f "${INPUT_DATAFILE}"
echo "::debug path=${INPUT_DATAFILE}::Storage location for badge json file"

INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-$3}"
INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-assets/images/credly-badges}"
INPUT_IMAGEDIR="${GITHUB_WORKSPACE}/${INPUT_IMAGEDIR}"
mkdir -p "${INPUT_IMAGEDIR}"
echo "::debug path=${INPUT_IMAGEDIR}::Storage location for badge image files"

URL="https://www.credly.com/users/${INPUT_USERNAME}/badges.json"
echo "::notice url=${URL}::Downloading infos from Credly"
curl --silent $URL \
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

BADGED_FOUND=$(jq '.[] | .id' "${INPUT_DATAFILE}" | wc -l)
echo "::notice::Found ${BADGED_FOUND} badges on Credly"

for line in $(jq --raw-output '.[] | (.image_url + "," + .id)' ${INPUT_DATAFILE}); do
    IFS=, read url id <<< $line

    outputFile="${INPUT_IMAGEDIR}/${id}.${url##*.}"    
    if [ -f $outputFile ]; then
        echo "::notice id=${id} url=${url} to=${outputFile}::Badge image for id ${id} already present - skip download"
    else
        echo "::notice id=${id} url=${url} to=${outputFile}::Downloading bage image for id ${id}"
        curl --silent "${url}" > $outputFile    
    fi
done