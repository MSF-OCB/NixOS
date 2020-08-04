FROM nixos/nix
RUN apk add --no-cache bash
COPY build.sh /nixos_build/
VOLUME /nix
CMD ["/nixos_build/build.sh"]

