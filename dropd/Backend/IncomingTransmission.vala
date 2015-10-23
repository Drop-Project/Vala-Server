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

[DBus (name = "org.dropd.IncomingTransmission")]
public class dropd.Backend.IncomingTransmission : ProtocolImplementation {
    public enum ServerState {
        AWAITING_REQUEST,
        NEEDS_CONFIRMATION,
        RECEIVING_DATA,
        FINISHED,
        FAILURE,
        CANCELED,
        REJECTED
    }

    public struct FileRequest {
        uint16 id;
        uint32 size;
        string name;
    }

    public signal void protocol_failed (string error_message);
    public signal void state_changed (ServerState state);

    private ServerState state = ServerState.AWAITING_REQUEST;

    private Gee.HashMap<int, FileRequest? > file_requests;

    public IncomingTransmission (TlsServerConnection connection) {
        base (connection.input_stream, connection.output_stream);

        new Thread<int> (null, () => {
            if (!receive_request ()) {
                protocol_failed (_("Receiving request failed."));

                return 0;
            }

            return 0;
        });
    }

    public ServerState get_state () {
        return state;
    }

    public FileRequest[] get_file_requests () {
        FileRequest[] requests = {};

        file_requests.@foreach ((entry) => {
            requests += entry.value;

            return true;
        });

        return requests;
    }

    private bool receive_request () {
        file_requests = new Gee.HashMap<int, FileRequest? > ();
        bool last_file = false;

        while (!last_file) {
            uint8[]? package = receive_package (CLIENT_COMMAND_FILE_REQUEST);

            if (package == null) {
                return false;
            }

            last_file = (package[1] == 1);

            uint16 id = (package[2] << 8) + package[3];
            uint32 size = (package[4] << 24) + (package[5] << 16) + (package[6] << 8) + package[7];
            package.move (8, 0, package.length - 7);
            string name = (string)package;

            debug ("File request received: #%u -> %s[%u Bytes]", id, name, size);

            file_requests.@set (id, { id, size, name });
        }

        return true;
    }

    private void update_state (ServerState state) {
        this.state = state;
        state_changed (state);
    }
}