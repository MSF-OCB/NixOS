FROM alpine
RUN apk add --no-cache ansible openssh-client
COPY . /nixos_deploy
WORKDIR nixos_deploy
CMD ["./deploy.sh"]

