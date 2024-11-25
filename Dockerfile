# syntax=docker/dockerfile:1

ARG BASE_BUILD_IMAGE_NAME=node
ARG BASE_BUILD_IMAGE_TAG=16.20.2-alpine3.18@sha256:72e89a86be58c922ed7b1475e5e6f151537676470695dd106521738b060e139d
ARG BASE_FINAL_IMAGE_NAME=nginx
ARG BASE_FINAL_IMAGE_TAG=1.25.4-alpine3.18@sha256:cb0953165f59b5cf2227ae979a49a2284956d997fad4ed7a338eebc6aef3e70b
ARG WORKDIR=/app

#  ---------------------------------------------------------------------------------
#  BUILD
#  ---------------------------------------------------------------------------------

FROM ${BASE_BUILD_IMAGE_NAME}:${BASE_BUILD_IMAGE_TAG} AS build

ARG WORKDIR

WORKDIR ${WORKDIR}

COPY --link \
    ./package-lock.json \
    ./package.json \
    ./

ENV npm_config_cache /tmp/npm_cache

ARG NPM_DOCKERFILE_CACHE_ID

RUN npm ci --prefer-offline

COPY --link . ./

ARG NPM_CONFIGURATION
ARG NPM_CONFIGURATION_ARGS=${NPM_CONFIGURATION:+"-${NPM_CONFIGURATION}"}
RUN npm run build${NPM_CONFIGURATION_ARGS}


#  ---------------------------------------------------------------------------------
#  TESTS
#  ---------------------------------------------------------------------------------

FROM build AS tests

ARG WORKDIR

WORKDIR ${WORKDIR}

RUN npm test


#  ---------------------------------------------------------------------------------
#  FINAL
#  ---------------------------------------------------------------------------------

FROM ${BASE_FINAL_IMAGE_NAME}:${BASE_FINAL_IMAGE_TAG} AS final

ARG WORKDIR

COPY --from=build ${WORKDIR}/dist /usr/share/nginx/html

LABEL maintainer="n98gt56ti@gmail.com"
