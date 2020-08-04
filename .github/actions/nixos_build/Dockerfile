FROM nixos/nix
RUN apk add --no-cache bash
COPY build.sh /nixos_build/
CMD ["/nixos_build/build.sh"]

