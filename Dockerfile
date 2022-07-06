FROM golang@sha256:0991060a1447cf648bab7f6bb60335d1243930e38420bee8fec3db1267b84cfa as builder

RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates

ENV USER=scratchuser
ENV UID=10001

RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"

WORKDIR $GOPATH/src/mypackage/myapp/

COPY . .

RUN go get -d -v
RUN go mod download
RUN go mod verify

RUN GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/hello

FROM scratch

ENV PATH="/bin:${PATH}"
COPY --from=ghcr.io/antyung88/scratch-sh:stable /lib /lib
COPY --from=ghcr.io/antyung88/scratch-sh:stable /bin /bin

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

COPY --from=builder /go/bin/hello /go/bin/hello

USER scratchuser:scratchuser

EXPOSE 8080
ENTRYPOINT ["/go/bin/hello"]
