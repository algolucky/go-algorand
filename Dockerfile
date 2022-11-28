FROM docker.io/library/golang:1.17.13-bullseye as build

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    autoconf \
    automake \
    build-essential \
    libboost-math-dev \
    libtool \
    sqlite3 && \
    rm -rf /var/lib/apt/lists/*

COPY . /go-algorand/

WORKDIR /go-algorand

RUN git submodule update --init && \
    make build

# do not include these in final container
RUN rm -rf /go/bin/COPYING

FROM docker.io/library/debian:bullseye-slim

# GOPATH is /go
# e.g. https://github.com/docker-library/golang/blob/326acd5eed36954174ba8b3b6d0efda96087e18a/1.19/alpine3.15/Dockerfile#L120
COPY --from=build /go/bin/ /usr/local/bin/
COPY --from=build /go-algorand/docker/entrypoint.sh /entrypoint.sh
COPY --from=build /go-algorand/docker/files/run/ /node/run/
COPY --from=build /go-algorand/installer/config.json.example /node/run/data/
COPY --from=build /go-algorand/installer/genesis/ /node/run/genesis/

# expose algod, gossip, and metrics ports
EXPOSE 8080 4160 9100

ENV ALGORAND_DATA /algod/data

ENTRYPOINT [ "/entrypoint.sh" ]
