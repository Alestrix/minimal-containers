# minimal-wsddn

Minimal wsddn daemon

## Purpose

`wsddn` is a C++ implememtaion of the WS-Discovery protocol by [Eugene Gershnik](https://gershnik.github.io/).
WSD replaces NetBIOS and its ugly broadcast-based protocol. 

The original wsdd was written in Python, wsdd2 in C, wsddn is a C++ implementation. See
[https://github.com/gershnik/wsdd-native](https://github.com/gershnik/wsdd-native) for details.

## NOTE

- untested
- will have to run with host networking (as it is using multicast)
- you must supply the samba server's hostname using -H option or using the WSDDN_HOSTNAME env variable
- see also [https://github.com/gershnik/wsdd-native?tab=readme-ov-file#docker](https://github.com/gershnik/wsdd-native?tab=readme-ov-file#docker)