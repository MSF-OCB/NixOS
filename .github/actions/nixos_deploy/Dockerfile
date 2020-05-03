FROM alpine
RUN apk add --no-cache ansible openssh-client
COPY . /nixos_deploy
CMD ["/nixos_deploy/deploy.sh"]

