FROM golang:alpine
RUN apk add --update git bash openssh
WORKDIR $GOPATH/src/github.com/hashicorp/terraform
ENV TF_DEV=true
RUN git clone https://github.com/cduongt/terraform.git ./ && \
    /bin/bash scripts/build.sh
RUN ls $GOPATH/bin

FROM centos:6
WORKDIR /docker-metapipe
COPY --from=0 /go/src/github.com/hashicorp/terraform/bin/terraform /bin
RUN rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum -y update && yum -y install git && yum -y install ansible && yum -y install python34
ADD https://raw.githubusercontent.com/EGI-FCTF/fedcloud-userinterface/master/fedcloud-ui.sh /docker-metapipe/fedcloud-ui.sh
RUN chmod +x fedcloud-ui.sh
RUN ./fedcloud-ui.sh
RUN mkdir /root/.globus
RUN ln -s /metapipe-files/usercert.pem $HOME/.globus/usercert.pem
RUN ln -s /metapipe-files/userkey.pem $HOME/.globus/userkey.pem
RUN git clone https://github.com/cduongt/mmg-cluster-setup-CESNET.git
RUN ln -s /metapipe-files/context mmg-cluster-setup-CESNET/context
RUN ln -s /metapipe-files/elixirx509 mmg-cluster-setup-CESNET/elixirx509
RUN rm mmg-cluster-setup-CESNET/mmg-cluster.tf
RUN ln -s /metapipe-files/mmg-cluster.tf mmg-cluster-setup-CESNET/mmg-cluster.tf
WORKDIR /docker-metapipe/mmg-cluster-setup-CESNET
VOLUME ["/tmp", "/metapipe-files"]