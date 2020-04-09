FROM alpine 

RUN apk add --no-cache python3 ansible openssh
COPY go.sh /go.sh
RUN chmod 0500 /go.sh

CMD ["/go.sh"]

