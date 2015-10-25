/*
 * Copyright (c) 2011-2015 Marcus Wichelmann (marcus.wichelmann@hotmail.de)
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
 */

public abstract class dropd.Backend.ProtocolImplementation : Object {
    /* Packages bigger than 2^14 bytes are truncated by gio. */
    protected static const uint16 MAX_PACKAGE_LENGTH = 16384;

    private InputStream input_stream;
    private OutputStream output_stream;

    protected ProtocolImplementation (InputStream input_stream, OutputStream output_stream) {
        this.input_stream = input_stream;
        this.output_stream = output_stream;
    }

    protected bool send_package (uint8[] data) {
        try {
            uint16 package_length = (uint16)(data.length);

            if (package_length > MAX_PACKAGE_LENGTH) {
                warning ("Sending package failed: Package too big.");

                return false;
            }

            output_stream.write ({ (uint8)((package_length >> 8) & 0xff), (uint8)(package_length & 0xff) });
            output_stream.write (data);

            return true;
        } catch (Error e) {
            warning ("Sending package failed: %s", e.message);

            return false;
        }
    }

    protected uint8[]? receive_package () {
        try {
            uint8[] header = new uint8[2];

            if (input_stream.read (header) != 2) {
                warning ("Receiving package failed: Invalid package header.");

                return null;
            }

            uint16 package_length = (header[0] << 8) + header[1];

            uint8[] package = new uint8[package_length];
            uint16 received_length = (uint16)input_stream.read (package);

            if (received_length != package_length) {
                warning ("Receiving package failed: Invalid package. Received %u of %u bytes.", received_length, package_length);

                return null;
            }

            return package;
        } catch (Error e) {
            warning ("Receiving package failed: %s", e.message);

            return null;
        }
    }
}