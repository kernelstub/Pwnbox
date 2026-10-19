{ pkgs, ... }:
with pkgs;
[
  netexec
  bloodhound-ce
  certipy
  coercer
  donpapi
  enum4linux-ng
  evil-winrm
  kerbrute
  samba
  freerdp
  responder
  (mitm6.override { python3 = python312; })
  krb5

  ldapnomnom
  rusthound-ce
  bloodhound-py
  pwnbox.sharphound
  adidnsdump
  pywhisker

  python3Packages.impacket
  pwnbox.impacket-tools
  python3Packages.pypykatz
  python3Packages.lsassy

  smbmap
  openldap
  python3Packages.ldapdomaindump
  python3Packages.pywerview
  python3Packages.ldap3
  python3Packages.minikerberos
  python3Packages.bloodyad
  python3Packages.kerbad
]
