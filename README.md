# Vala-Server
Reference implementation of the Drop protocol for Linux. This repository contains a daemon (dropd), a library (libdrop-1.0) for easier communication via DBus and a simple user-interface (drop-dialog) for sending files to another device.

## Dependencies
* cmake
* valac
* libgtk-3-dev
* libgranite-dev
* libgee-0.8-dev
* libavahi-gobject-dev
* libavahi-client-dev`

## Installation
```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
sudo make install
```

## Certificate
Until now it's required to generate the TLS certificate used by the server manually by executing `sudo openssl req -nodes -new -x509 -keyout /usr/share/drop/key.pem -out /usr/share/drop/cert.pem -days 365`

## Execution
To run the daemon on your pc type `dropd` or `dropd -d` for further debugging output. The sending dialog can be opened by executing `drop-dialog`.

## Library documentation
This server ships a library that handles the whole communication part between your integration and the Drop daemon. You can browse it's documentation here:
[http://drop-project.github.io/Vala-Server](http://drop-project.github.io/Vala-Server/drop-1.0/index.htm)
