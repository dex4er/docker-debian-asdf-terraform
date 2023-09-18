## $ docker build --tag dex4er/debian-asdf-terraform --squash .

ARG DEBIAN_ASDF_TAG=latest
ARG TF_VERSION=v2.8.0
ARG VERSION=latest

ARG BUILDDATE
ARG REVISION


FROM dex4er/debian-asdf:${DEBIAN_ASDF_TAG}

ARG BUILDDATE
ARG REVISION
ARG TF_VERSION
ARG VERSION

ADD https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /usr/local/share/ca-certificates/global-bundle.crt

RUN update-ca-certificates

COPY .tool-versions /root/
COPY entrypoint.sh /

RUN while read -r plugin _version; do test -d ~/.asdf/plugins/"$plugin" || asdf plugin add "$plugin"; done < .tool-versions
RUN asdf install

RUN asdf list

ADD https://github.com/dex4er/tf/releases/download/${TF_VERSION}/tf-linux-amd64 /usr/local/bin/tf
RUN chmod +x /usr/local/bin/tf

RUN tf version

RUN apt-get -q -y autoremove
RUN find /var/cache/apt /var/lib/apt/lists /var/log -type f -delete

ENTRYPOINT [ "/entrypoint.sh" ]

LABEL \
  maintainer="Piotr Roszatycki <piotr.roszatycki@gmail.com>" \
  org.opencontainers.image.created=${BUILDDATE} \
  org.opencontainers.image.description="Container image with AWS CLI, Infracost and Terraform" \
  org.opencontainers.image.licenses="MIT" \
  org.opencontainers.image.revision=${REVISION} \
  org.opencontainers.image.source=https://github.com/dex4er/docker-debian-asdf-terraform \
  org.opencontainers.image.title=debian-asdf-terraform \
  org.opencontainers.image.url=https://github.com/dex4er/docker-debian-asdf-terraform \
  org.opencontainers.image.vendor=dex4er \
  org.opencontainers.image.version=${VERSION}
