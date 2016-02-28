#!/bin/sh

rm -rf doc
valadoc \
--importdir=/usr/share/gir-1.0 \
--vapidir=/usr/share/vala-0.30/vapi \
--vapidir=/usr/share/vala/vapi \
--directory=doc \
--package-name=drop-1.0 \
--pkg=drop-1.0 \
/usr/share/vala/vapi/drop-1.0.vapi