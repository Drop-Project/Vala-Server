/*
 * Copyright (c) 2011-2015 Drop Developers
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Marcus Wichelmann <marcus.wichelmann@hotmail.de>
 */

public abstract class DropDaemon.Backend.ProtocolImplementation : Object {
    /* Packages bigger than 2^14 bytes are truncated by gio. */
    protected static const uint16 MAX_PACKAGE_LENGTH = 16384;

    public Cancellable cancellable;

    private InputStream input_stream;
    private OutputStream output_stream;

    protected ProtocolImplementation (InputStream input_stream, OutputStream output_stream) {
        this.input_stream = input_stream;
        this.output_stream = output_stream;

        cancellable = new Cancellable ();
    }

    protected bool send_package (uint8[] data) {
        try {
            uint16 package_length = (uint16)(data.length);

            if (package_length > MAX_PACKAGE_LENGTH) {
                warning ("Sending package failed: Package too big.");

                return false;
            }

            output_stream.write_all ({ (uint8)((package_length >> 8) & 0xff), (uint8)(package_length & 0xff) }, null, cancellable);
            output_stream.write_all (data, null, cancellable);

            return true;
        } catch (Error e) {
            warning ("Sending package failed: %s", e.message);

            return false;
        }
    }

    protected uint8[]? receive_package (uint16 expected_min_length = 1) {
        try {
            size_t header_length;
            uint8[] header = new uint8[2];

            if (!input_stream.read_all (header, out header_length, cancellable)) {
                warning ("Receiving package failed: Error while reading header.");

                return null;
            }

            if (header_length != 2) {
                warning ("Receiving package failed: Invalid package header.");

                return null;
            }

            uint16 expected_package_length = (header[0] << 8) + header[1];

            if (expected_package_length < expected_min_length) {
                warning ("Receiving package failed: Package size %u too small.", expected_package_length);

                return null;
            }

            size_t package_length;
            uint8[] package = new uint8[expected_package_length];

            if (!input_stream.read_all (package, out package_length, cancellable)) {
                warning ("Receiving package failed: Error while reading package.");

                return null;
            }

            if (package_length != expected_package_length) {
                warning ("Receiving package failed: Invalid package. Received %u of %u bytes.", (uint16)package_length, expected_package_length);

                return null;
            }

            return package;
        } catch (Error e) {
            warning ("Receiving package failed: %s", e.message);

            return null;
        }
    }
}