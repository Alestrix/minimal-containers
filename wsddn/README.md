# minimal-wsddn

Minimal wsddn/wsdd2 daemon

## Purpose

`wsddn` is a C++ implememtaion of the WS-Discovery protocol. It replaces NetBIOS and its ugly broadcast-based protocol. 

The original wsdd was written in Python, wsddn is a C-native implementation. See
[https://github.com/gershnik/wsdd-native](https://github.com/gershnik/wsdd-native)

## NOTE

- untested
- will have to run with host networking (as it is using multicast)
- you must supply the samba server's hostname using -H option