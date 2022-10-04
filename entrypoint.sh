#!/usr/bin/env bash
set -e

INPUT_USERNAME="${INPUT_USERNAME:-$1}"
echo "::debug::Credly username: ${INPUT_USERNAME}"

INPUT_DATAFILE="${INPUT_DATAFILE:-$2}"
INPUT_DATAFILE="${INPUT_DATAFILE:-credly-badges.json}"
INPUT_DATAFILE="${GITHUB_WORKSPACE}/data/${INPUT_DATAFILE}"
mkdir -p "$(dirname ${INPUT_DATAFILE})"
rm -f "${INPUT_DATAFILE}"
echo "::debug::Storage location for badge json file: ${INPUT_DATAFILE}"

INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-$3}"
INPUT_IMAGEDIR="${INPUT_IMAGEDIR:-assets/images/credly-badges}"
INPUT_IMAGEDIR="${GITHUB_WORKSPACE}/${INPUT_IMAGEDIR}"
mkdir -p "${INPUT_IMAGEDIR}"
echo "::debug::Storage location for badge image files: ${INPUT_IMAGEDIR}"

URL="https://www.credly.com/users/${INPUT_USERNAME}/badges.json"
echo "::debug::Credly json url: ${URL}"
echo "::notice::Downloading infos from Credly"
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
        echo "::notice::Badge image for id ${id} already present - skipping download"
    else
        echo "::notice::Downloading bage image for id ${id}"
        curl --silent "${url}" > $outputFile    
    fi
done