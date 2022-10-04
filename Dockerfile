FROM alpine:3.16

RUN apk add --no-cache bash jq curl

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
