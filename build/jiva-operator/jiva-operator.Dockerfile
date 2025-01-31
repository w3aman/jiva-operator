# Copyright © 2019-2020 The OpenEBS Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM golang:1.17.6 as build

ARG BRANCH
ARG RELEASE_TAG
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT=""

ENV GO111MODULE=on \
  GOOS=${TARGETOS} \
  GOARCH=${TARGETARCH} \
  GOARM=${TARGETVARIANT} \
  DEBIAN_FRONTEND=noninteractive \
  PATH="/root/go/bin:${PATH}" \
  BRANCH=${BRANCH} \
  RELEASE_TAG=${RELEASE_TAG}

WORKDIR /go/src/github.com/openebs/jiva-operator/

RUN apt-get update && apt-get install -y make git

COPY go.mod go.sum ./
# Get dependancies - will also be cached if we won't change mod/sum
RUN go mod download

COPY . .

RUN make buildx.jiva-operator

FROM ubuntu:18.04

ENV OPERATOR=/usr/local/bin/jiva-operator \
    USER_UID=1001 \
    USER_NAME=jiva-operator

ARG DBUILD_DATE
ARG DBUILD_REPO_URL
ARG DBUILD_SITE_URL

# install operator binary
COPY --from=build /go/src/github.com/openebs/jiva-operator/build/bin/jiva-operator ${OPERATOR}
COPY --from=build /go/src/github.com/openebs/jiva-operator/build/jiva-operator/entrypoint /usr/local/bin/
COPY --from=build /go/src/github.com/openebs/jiva-operator/build/jiva-operator/user_setup /usr/local/bin/

RUN  /usr/local/bin/user_setup

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="jiva-operator"
LABEL org.label-schema.description="OpenEBS Jiva Operator"
LABEL org.label-schema.build-date=$DBUILD_DATE
LABEL org.label-schema.vcs-url=$DBUILD_REPO_URL
LABEL org.label-schema.url=$DBUILD_SITE_URL
LABEL org.label-schema.arch=$ARCH

ENTRYPOINT ["/usr/local/bin/entrypoint"]

USER ${USER_UID}
