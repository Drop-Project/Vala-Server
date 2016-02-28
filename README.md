# Vala-Server
Reference implementation of the Drop protocol for Linux. This repository contains a daemon (dropd), a library (libdrop-1.0) for easier communication via DBus and a simple user-interface (drop-dialog) for sending files to another device.

## Installation
```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
sudo make install
```

## Certificate
Until now it's required to generate the TLS certificate used by the server manually by executing the following commands:

## Execution
To run the daemon on your pc type `dropd` or `dropd -d` for further debugging output. The sending dialog can be opened by executing `drop-dialog`.
