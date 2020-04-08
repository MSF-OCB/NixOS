FROM alpine 

ENV ANSIBLE_HOST_KEY_CHECKING=False

RUN apk add --no-cache python3 ansible openssh git
COPY deploy.sh /deploy.sh
RUN chmod 0700 /deploy.sh

CMD ["/deploy.sh"]

