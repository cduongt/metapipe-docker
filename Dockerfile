FROM golang:alpine
RUN apk add --update git bash openssh make
WORKDIR $GOPATH/src/github.com/hashicorp/terraform
ENV TF_DEV=true
RUN git clone https://github.com/cduongt/terraform.git ./ && \
    make dev

FROM centos:6
WORKDIR /metapipe-install
COPY --from=0 /go/src/github.com/hashicorp/terraform/bin/terraform /bin
RUN yum -y install git wget epel-release openssh-clients
RUN yum -y update && yum -y install ansible python34 
RUN echo -e "[defaults]\nhost_key_checking = False" >> $HOME/.ansible.cfg
ADD https://raw.githubusercontent.com/EGI-FCTF/fedcloud-userinterface/master/fedcloud-ui.sh /metapipe-install/fedcloud-ui.sh
RUN chmod +x fedcloud-ui.sh
RUN ./fedcloud-ui.sh
RUN mkdir $HOME/.globus
RUN ln -s /metapipe-files/mmg-cluster-setup-CESNET/usercert.pem $HOME/.globus/usercert.pem
RUN ln -s /metapipe-files/mmg-cluster-setup-CESNET/userkey.pem $HOME/.globus/userkey.pem
RUN mkdir $HOME/.ssh
RUN ln -s /metapipe-files/mmg-cluster-setup-CESNET/id_rsa $HOME/.ssh/id_rsa
WORKDIR /metapipe-files/mmg-cluster-setup-CESNET
VOLUME ["/tmp", "/metapipe-files"]