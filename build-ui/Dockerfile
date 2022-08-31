FROM node:lts-alpine as builder

WORKDIR /srv/app
RUN npm ci \
 && npm run build:prod \
 && cp -R /srv/app /tmp/app

FROM node:lts-alpine

COPY --from=builder /tmp/app/dist/s3gw-ui /app
COPY entrypoint.sh /usr/bin/entrypoint.sh

RUN apk --no-cache add gettext \
 && npm install -g http-server \
 && chmod +x /usr/bin/entrypoint.sh

WORKDIR /app
STOPSIGNAL SIGINT
EXPOSE 8080
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
