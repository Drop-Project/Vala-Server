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

[DBus (name = "org.dropd.OutgoingTransmission")]
public class dropd.Backend.OutgoingTransmission : ProtocolImplementation {
    public enum ClientState {
        SENDING_REQUEST,
        AWAITING_CONFIRMATION,
        SENDING_DATA,
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
    public signal void state_changed (ClientState state);

    public ClientState state { get; private set; default = ClientState.SENDING_REQUEST; }

    public OutgoingTransmission (SocketConnection connection) {
        base (connection.input_stream, connection.output_stream);

        new Thread<int> (null, () => {
            if (!send_request ()) {
                protocol_failed (_("Sending request failed."));

                return 0;
            }

            return 0;
        });
    }

    private bool send_request () {
        return true;
    }

    private void update_state (ClientState state) {
        this.state = state;
        state_changed (state);
    }
}