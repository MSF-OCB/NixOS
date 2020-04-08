FROM alpine 

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache python3 ansible openssh git
COPY go.sh /go.sh
RUN chmod 0500 /go.sh

CMD ["/go.sh"]

