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
        AWAITING_INITIALISATION,
        AWAITING_REQUEST,
        NEEDS_CONFIRMATION,
        SENDING_CONFIRMATION,
        REJECTED,
        RECEIVING_DATA,
        FINISHED,
        CANCELED,
        FAILURE
    }

    public struct FileRequest {
        uint16 id;
        uint64 size;
        string name;
        bool accepted;
    }

    public signal void protocol_failed (string error_message);
    public signal void state_changed (ServerState state);

    private ServerState state = ServerState.AWAITING_INITIALISATION;

    private uint8 client_version;
    private string client_name;
    private Gee.HashMap<int, FileRequest? > file_requests;

    public IncomingTransmission (TlsServerConnection connection) {
        base (connection.input_stream, connection.output_stream);

        new Thread<int> (null, () => {
            if (!receive_initialisation ()) {
                protocol_failed (_("Receiving request failed."));
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.AWAITING_REQUEST);

            if (!receive_request ()) {
                protocol_failed (_("Receiving request failed."));
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.NEEDS_CONFIRMATION);

            return 0;
        });
    }

    public void reject_transmission () {
        if (state != ServerState.NEEDS_CONFIRMATION) {
            return;
        }

        update_state (ServerState.SENDING_CONFIRMATION);

        new Thread<int> (null, () => {
            send_confirmation (false);

            update_state (ServerState.REJECTED);

            return 0;
        });
    }

    public void accept_transmission (uint16[] accepted_ids) {
        if (state != ServerState.NEEDS_CONFIRMATION) {
            return;
        }

        update_state (ServerState.SENDING_CONFIRMATION);

        new Thread<int> (null, () => {
            send_confirmation (true, accepted_ids);

            update_state (ServerState.RECEIVING_DATA);

            return 0;
        });
    }

    public ServerState get_state () {
        return state;
    }

    public uint8 get_client_version () {
        return client_version;
    }

    public string get_client_name () {
        return client_name;
    }

    public FileRequest[] get_file_requests () {
        FileRequest[] requests = {};

        file_requests.@foreach ((entry) => {
            requests += entry.value;

            return true;
        });

        return requests;
    }

    private bool receive_initialisation () {
        uint8[]? package = receive_package ();

        if (package == null) {
            return false;
        }

        client_version = package[0];

        package.move (1, 0, package.length);

        client_name = (string)package;

        return true;
    }

    private bool receive_request () {
        file_requests = new Gee.HashMap<int, FileRequest? > ();
        bool last_file = false;

        do {
            uint8[]? package = receive_package ();

            if (package == null) {
                return false;
            }

            last_file = (package[0] == 1);

            uint16 id = (package[1] << 8) +
                        package[2];

            uint64 size = ((uint64)package[3] << 32) +
                          ((uint32)package[4] << 24) +
                          ((uint32)package[5] << 16) +
                          ((uint16)package[6] << 8) +
                          (uint8)package[7];

            package.move (8, 0, package.length - 7);
            string name = (string)package;

            debug ("File request received: #%u -> %s[%s Bytes]", id, name, size.to_string ());

            file_requests.@set (id, { id, size, name, false });
        } while (!last_file);

        return true;
    }

    private void send_confirmation (bool accepted, uint16[]? accepted_ids = null) {
        bool accept = (accepted && accepted_ids != null);

        uint8[] package = {};
        package += (accept ? 1 : 0);

        if (accept) {
            foreach (uint16 id in accepted_ids) {
                package += (uint8)(id >> 8) & 0xff;
                package += (uint8)id & 0xff;
            }
        }

        send_package (package);
    }

    private void update_state (ServerState state) {
        debug ("State changed to %s", state.to_string ());

        this.state = state;
        state_changed (state);
    }
}