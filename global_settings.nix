{
  
  default_users = [ ./users/msfocb.nix
                    ./users/ramses.nix
                    ./users/manu.nix
                    ./users/mohammad.nix
                    ./users/thierry.nix ];

  reverse_tunnel_config = [ { name = "google";     host = "msfrelay1.msfict.info";     port_prefix = "";  }
                            { name = "ixelles";    host = "ehealthsshrelayhq1.msf.be"; port_prefix = "";  }
                            { name = "ixelles-ip"; host = "194.78.17.132";             port_prefix = "1"; } ];

  # python2 -c 'import crypt, getpass,os,base64; print crypt.crypt(getpass.getpass(), "$6$"+base64.b64encode(os.urandom(16))+"$")'
  admin_user_hashedPassword = "$6$fdEP2xGs$2qw.bg8Mb5ohQvIl3UAbr65Mi9C.m4qXs9R.Vc7TqZVemxt3AfF5oQNNZZwbyYd/MrVd2UMGjW4jQAcYFvgLJ/";

}

