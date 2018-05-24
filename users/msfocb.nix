{ config, lib, pkgs, ... }:

{
  users.extraUsers.msfocb = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    # python2 -c 'import crypt, getpass,os,base64; print crypt.crypt(getpass.getpass(), "$6$"+base64.b64encode(os.urandom(16))+"$")'
    hashedPassword = "$6$fdEP2xGs$2qw.bg8Mb5ohQvIl3UAbr65Mi9C.m4qXs9R.Vc7TqZVemxt3AfF5oQNNZZwbyYd/MrVd2UMGjW4jQAcYFvgLJ/";
    openssh.authorizedKeys.keyFiles = [
      ../keys/msfocb
    ];
  };
}

