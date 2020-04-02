
########################################################################
#                                                                      #
# DO NOT EDIT THIS FILE, ALL EDITS SHOULD BE DONE IN THE GIT REPO,     #
# PUSHED TO GITHUB AND PULLED HERE.                                    #
#                                                                      #
# LOCAL EDITS WILL BE OVERWRITTEN.                                     #
#                                                                      #
########################################################################

{

  settings.reverse_tunnel = {
    relay_servers = {
      sshrelay1.host = "sshrelay1.msf.be";
      sshrelay2.host = "sshrelay2.msf.be";
      sshrelay1-ip = { host = "185.199.180.11"; ip_tunnel = true; };
      sshrelay2-ip = { host = "15.188.17.148";  ip_tunnel = true; };
    };
    tunnels = {
      benuc001 = {
        remote_forward_port = 6001;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILb9xUaLuux8HW8RM0XuA/UTW2GZ1xuf4rSmmL+KrAue";
      };
      benuc002 = {
        remote_forward_port = 6002;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA3YY2F1iOlm/7w9dSXzHU6ZbOuUx9oMwpfi5xFm6jrz";
      };
      benuc004 = {
        remote_forward_port = 6004;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID4Z8H11e/KObgnRN2m+scZXNzPJ1ihYEv4QeilB7gFQ";
      };
      benuc005 = {
        remote_forward_port = 6005;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBZYkWxsw65JIMWQh305cSN7T0MAxh6STvnGZS398Yr";
      };
      benuc006 = {
        remote_forward_port = 6006;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvMWiaQODn3tTMbAok3hEBSWNB46LvIGlq/kGh8Nkrn";
      };
      benuc007 = {
        remote_forward_port = 6007;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKmsAAfh4Mp4DwW5ZJHHuH0NIS5aXOEgauv/7IibUwmJ";
      };
      benuc009 = {
        remote_forward_port = 6009;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIORkuDKoeQNl2zbgkVcjvwzp3sycaUyesMfuWqpVJ7Hj";
      };
      benuc010 = {
        remote_forward_port = 6010;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2hnXQtCxCRziexeMMDV2CgstJTuESWWH5BtTkPgFTL";
      };
      benuc011 = {
        remote_forward_port = 6011;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINQ/Y2JYGo76I8SmqX9yMOXHHpCiC/o7bkPq2nPnWWj2";
      };
      benuc012 = {
        remote_forward_port = 6012;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEY+a/keYuVeQcp6ckhFGbh1I+w9idqcz6uJWc65bz1/";
      };
      benuc013 = {
        remote_forward_port = 6013;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLmmydD6WB7IP1izvvNZDV9A6mZkh/AWhas+Av+BMQo";
      };
      benuc014 = {
        remote_forward_port = 6014;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINXJbOb4xcVEQ9EZMGv9FdLdfsApkyu3G/aU0CXpwrN4";
      };
      benuc015 = {
        remote_forward_port = 6015;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIVtHmT5asI8gTxfkjQF0ckWuYjpIbfn2JQ//3cW6IT";
      };
      benuc016 = {
        remote_forward_port = 6016;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC4SKKoo5s/l8Zz6KiFXvaaB36BTwOPvL+9EZ075eyxN";
      };
      benuc017 = {
        remote_forward_port = 6017;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA4u0syoSXPKK/I7pEfYlGilsnR5ru5Jidmsx+/WP1Wx";
      };
      benuc018 = {
        remote_forward_port = 6018;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAFLh8bFTA1reu4FbRaHypNmUbnDHFaDeuCK1VN1av2Q";
      };
      benuc019 = {
        remote_forward_port = 6019;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK69hSz4grSnzhE1nj8p/t6CyDCprNJLSHmuY/0SpMyk";
      };
      benuc020 = {
        remote_forward_port = 6020;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqa8YNEltJ6GnG5JEcIzEwj7qCUhX8BSaf54B5cJz5f";
      };
      benuc021 = {
        remote_forward_port = 6021;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM5tKDAj846OZYE2QboDY2rLCJGqD2TpIwLkyTAxqFNp";
      };
      benuc022 = {
        remote_forward_port = 6022;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICbo4JI5wprBXVP+AWAAdOc5iocH9/l12tj2nqAHxEuv";
      };
      benuc023 = {
        remote_forward_port = 6023;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+8R/MbylKioF/G1Pgz5UuHjvm/g07k694xBsORuFD3";
      };
      benuc024 = {
        remote_forward_port = 6024;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDPpyoiz6zAbFIpbWHAQNU+kzDL/fa4/W8Sj/61myKq";
      };
      benuc025 = {
        remote_forward_port = 6025;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHb9NxZ9dn31hgZLqMrSBsBAvJRYfPXDxuWuq8dPmD7";
      };
      benuc026 = {
        remote_forward_port = 6026;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6ZDpVKrZmVPKhj7nV6+G6XGfVlwkGbBo5nfBc9Ob5M";
      };
      benuc027 = {
        remote_forward_port = 6027;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmYS2/DQBE+UXz9RXaRosY2DqNPkd4kmjC6plz6buFO";
      };
      benuc028 = {
        remote_forward_port = 6028;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUn9fq8+V777HPsIsHGuwqO9GUx2eb3VgXfb4AlMrFc";
      };
      benuc030 = {
        remote_forward_port = 6030;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuO71LJMkLVfiOfbqAcAKHalF09I4yKFE2ie+rNO4VV";
      };
      benuc031 = {
        remote_forward_port = 6031;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpUheP9/ayG3w4331ImJ1hGiO4vazhbFHY1S9Pin8hM";
      };
      benuc032 = {
        remote_forward_port = 6032;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXDFSSLf4Hzdj8od4lvvgbNMT2DOlGatgBxPTl/aRMj";
      };
      benuc033 = {
        remote_forward_port = 6033;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKUVpiGfmP49DsYm8V88dh0lFy3AT9CWzjtYOVqhb9kK";
      };
      benuc034 = {
        remote_forward_port = 6034;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3/H1ZLfvEiCgKTTAi7Kv5nLs13exCE18Qs91huUUQf";
      };
      benuc035 = {
        remote_forward_port = 6035;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBO4EEELvHYDFXwwdWAbDa40g/G160sp97KBHyBXujW1";
      };
      benuc036 = {
        remote_forward_port = 6036;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPw9UgvPwmXlmgzcZnc5AUs1R76dSJ+dIBSQlTHbKp8Q";
      };
      benuc037 = {
        remote_forward_port = 6037;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaAU2Qlb28bitzczfW9ERHu2AUXmXSMsPcz3TsXwRzR";
      };
      chk-emr-a = {
        remote_forward_port = 7000;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7bD80cOfb9YEGDSwOk6KmkF/IQsDtPe4tRdL9MUfws";
      };
      bevm001 = {
        remote_forward_port = 9001;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO2jw/FNwLsJBURo344HnlPKByXLnRw02J0Tjqu8l1ja";
      };
      bevm002 = {
        remote_forward_port = 9002;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAyvA6grKqwe8qkR2B08I3eyJ96yxjXZtTj/i7Fyfv4z";
      };
      bevm003 = {
        remote_forward_port = 9003;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN04wfoNBSMgmiYqRz75ctBT05xs0nY0HrElvQRtif0r";
      };
      MumbaiActive = {
        remote_forward_port = 7020;
        public_key = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAA2w/wBWWGS8aUkPsDO+zWOIVBsxCV9dF9QYWVDCJGmkvkBqbGJEl9DT1o+STp6mGhCsNp1IfCVcCWEI3LPQA8umwHySxDgKh9aYRjIW3I3w78c+HTcjxjUPGgQt4myo4m0QqurXBj2KDcyi/lpgop4PUhXtCByvdyxkGhsiW/oPpo5Og==";
      };
      nixos-dev = {
        remote_forward_port = 7030;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgwv/W8crzBaLATRbL+8NvKXv26IyqUPHagKMsfJtua";
      };
      maadi-emr-a = {
        remote_forward_port = 7040;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJmymppxqPWu8vgMMvwTf2mZZrGt7sAjKtEPZnJIMxbf";
      };
      dhis2-dev = {
        remote_forward_port = 7050;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExJL0OkpgTQa7COq1N4feKpzLnNsIk9DqoJpTYSB+6a";
      };
      dhis2-metadata = {
        remote_forward_port = 7051;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDP7/n9tNYYsvFX3BcbYbaoZ/90d5upvc4L241MVoSOd";
      };
      dhis2-hq-remote = {
        remote_forward_port = 7052;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP/8mX0le0REpC5dXsBQy4LdL11E+TpXqI/IvlRTg3um";
      };
      dhis2-hq-monitoring = {
        remote_forward_port = 7053;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOGEOzDi8fS1SqErixkM3WtewMdguJGu2QNQ4fIQEUv8";
      };
      dhis2-prod = {
        remote_forward_port = 7054;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMnoBNuvdpakfTZYQ92Ygu9IikZZedpD5lZMfKxloAv";
      };
      dhis2-validation = {
        remote_forward_port = 7055;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINf/aymMFW0dINiWZBV/PvXSabbEG1Nfg7gZxGCMWOQr";
      };
      aws-staging = {
        remote_forward_port = 7070;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILiYE4oyVHiWIW54GNEAIY2VlYzh9m46hp3e7ARTUrTI";
      };
      lndict = {
        remote_forward_port = 7080;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsm64gHHwzyJ4FbQ+bWtLdEO7Kp5GIC5xXVg24cHMWQ";
      };
      nas-lab = {
        remote_forward_port = 7090;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOwCAHbUQeSnMnAPYV5LzHo89c0JxAo9h5ymlRO0n9Ph";
      };
      docker-dmz-1 = {
        remote_forward_port = 7100;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICGJiqyc8QDf1Yr0bb1bUJVLAqw1bMSZhkQyWasMpTtr";
      };    
      docker-dmz-2 = {
        remote_forward_port = 7101;
        public_key = "";
      };    
      rescue-iso = {
        remote_forward_port = 8000;
        public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDPkVmtj3Jkh/8tLJP+tE0/t3GMWJj6mVQ/PfkF7wIL6";
      };
    };
  };
}

