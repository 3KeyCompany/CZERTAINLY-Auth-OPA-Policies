FROM nginx:1.25.1-alpine as build

MAINTAINER CZERTAINLY <support@czertainly.com>

COPY ./policies /usr/share/nginx/html/bundles/policies

WORKDIR /usr/share/nginx/html/bundles

RUN curl -L -o opa https://openpolicyagent.org/downloads/v0.45.0/opa_linux_amd64_static && chmod 755 ./opa
RUN ./opa build -b policies
RUN rm -r policies && rm opa

# package to rootless image
FROM nginxinc/nginx-unprivileged:1.25.4-alpine

COPY --from=build /usr/share/nginx/html /usr/share/nginx/html