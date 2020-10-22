FROM teamserverless/license-check:0.3.6 as license-check

FROM golang:1.15-alpine as build

ARG TARGETARCH

ENV GO11MODULE=off
ENV CGO_ENABLED=0
ENV CGO_ENABLED=0
ENV GOARCH=${TARGETARCH}

ARG GIT_COMMIT_SHA
ARG VERSION='dev'

COPY --from=license-check /license-check /usr/bin/

WORKDIR /go/src/github.com/openfaas/faas-netes

COPY go.mod         .
COPY go.sum         .
COPY main.go        .
COPY pkg            pkg
COPY version        version

RUN license-check -path ./ --verbose=false "Alex Ellis" "OpenFaaS Author(s)"

RUN test -z "$(gofmt -l $(find . -type f -name '*.go'))"

COPY vendor         vendor

RUN if [ $TARGETARCH == "amd64" ]; then go test $(go list ./... | grep -v integration | grep -v /vendor/ | grep -v /template/) -cover; fi

RUN go build \
    -trimpath -ldflags="-buildid= -w -s \
        -X github.com/openfaas/faas-netes/version.GitCommit=${GIT_COMMIT_SHA} \
        -X github.com/openfaas/faas-netes/version.Version=${VERSION}" \
    -o faas-netes .

FROM alpine:3.12 as ship

ARG TARGETARCH

LABEL org.label-schema.license="MIT"
LABEL org.label-schema.vcs-url="https://github.com/openfaas/faas-netes"
LABEL org.label-schema.vcs-type="Git"
LABEL org.label-schema.name="openfaas/faas-netes"
LABEL org.label-schema.vendor="openfaas"
LABEL org.label-schema.docker.schema-version="1.0"

RUN addgroup -S app \
    && adduser -S -g app app \
    && apk add --no-cache ca-certificates

WORKDIR /home/app

EXPOSE 8080

ENV http_proxy      ""
ENV https_proxy     ""

COPY --from=build /go/src/github.com/openfaas/faas-netes/faas-netes    .
RUN chown -R app:app ./

USER app

CMD ["./faas-netes"]
