#!/bin/sh

rm -rf doc
valadoc \
--importdir=/usr/share/gir-1.0 \
--vapidir=/usr/share/vala-0.30/vapi \
--vapidir=/usr/share/vala/vapi \
--directory=doc \
--pkg=gio-2.0 \
--pkg=drop-1.0 \
--deps