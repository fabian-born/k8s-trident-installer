# Based on Alpine Linux
FROM ubuntu:18.04
LABEL maintainer="Fabian Born <git@fabianborn.net>"

RUN apt-get update \
    && apt-get install -y --no-install-recommends git curl wget

RUN apt-get update && apt-get install -y apt-transport-https gnupg2 snap
RUN curl -kLO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
COPY scripts/startup.sh /startup.sh
ENTRYPOINT "/startup.sh"
