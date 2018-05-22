{ config, lib, pkgs, ... }:

{
  users.extraUsers.root = {
    hashedPassword = "!";
  };
}
