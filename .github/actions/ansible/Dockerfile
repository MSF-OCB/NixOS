FROM alpine 

RUN apk add --no-cache python3 ansible openssh-client
COPY deploy.sh /deploy.sh
RUN chmod 0500 /deploy.sh

CMD ["/deploy.sh"]

