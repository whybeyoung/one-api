FROM --platform=$BUILDPLATFORM artifacts.iflytek.com/docker-private/maas/node:16  AS builder

WORKDIR /web
COPY ./VERSION .
COPY ./web .

WORKDIR /web/default
RUN npm config set registry https://registry.npmmirror.com/ && npm install
RUN DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat VERSION) npm run build

WORKDIR /web/berry
RUN npm config set registry https://registry.npmmirror.com/ &&  npm install
RUN DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat VERSION) npm run build

WORKDIR /web/air
RUN npm config set registry https://registry.npmmirror.com/ && npm install
RUN DISABLE_ESLINT_PLUGIN='true' REACT_APP_VERSION=$(cat VERSION) npm run build

FROM artifacts.iflytek.com/docker-private/maas/golang:alpine AS builder2

RUN apk add --no-cache g++

ENV GO111MODULE=on \
    CGO_ENABLED=1 \
    GOOS=linux

WORKDIR /build
ADD go.mod go.sum ./
RUN go env -w GOPROXY=https://goproxy.cn,direct &&  go mod download
COPY . .
COPY --from=builder /web/build ./web/build
RUN go build -trimpath -ldflags "-s -w -X 'github.com/songquanpeng/one-api/common.Version=$(cat VERSION)' -extldflags '-static'" -o one-api

FROM artifacts.iflytek.com/docker-private/maas/alpine:latest

RUN apk update \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && update-ca-certificates 2>/dev/null || true

COPY --from=builder2 /build/one-api /
EXPOSE 3000
WORKDIR /data
COPY start.sh /start.sh
