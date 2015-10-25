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
        LOADING_FILES,
        SENDING_INITIALISATION,
        SENDING_REQUEST,
        AWAITING_CONFIRMATION,
        REJECTED,
        SENDING_DATA,
        FINISHED,
        CANCELED,
        FAILURE
    }

    public struct FileRequest {
        uint16 id;
        uint64 size;
        string name;
        string filename;
        bool accepted;
    }

    public signal void protocol_failed (string error_message);
    public signal void state_changed (ClientState state);

    private ClientState state = ClientState.LOADING_FILES;

    private Gee.HashMap<int, FileRequest? > file_requests;

    public OutgoingTransmission (SocketConnection connection, string client_name, string[] files) {
        base (connection.input_stream, connection.output_stream);

        new Thread<int> (null, () => {
            if (!load_files (files)) {
                protocol_failed (_("Loading files failed."));
                update_state (ClientState.FAILURE);

                return 0;
            }

            update_state (ClientState.SENDING_INITIALISATION);

            send_initialisation (client_name);

            update_state (ClientState.SENDING_REQUEST);

            send_request ();

            update_state (ClientState.AWAITING_CONFIRMATION);

            if (!receive_confirmation ()) {
                protocol_failed (_("Receiving confirmation failed."));
                update_state (ClientState.FAILURE);

                return 0;
            }

            if (state == ClientState.SENDING_DATA) {
                if (!send_data ()) {
                    protocol_failed (_("Sending files failed."));
                    update_state (ClientState.FAILURE);

                    return 0;
                }
            }

            return 0;
        });
    }

    public ClientState get_state () {
        return state;
    }

    private bool load_files (string[] files) {
        file_requests = new Gee.HashMap<int, FileRequest? > ();

        if (files.length == 0) {
            warning ("No files specified.");

            return false;
        }

        try {
            foreach (string filename in files) {
                File file = File.new_for_path (filename);

                if (!file.query_exists ()) {
                    warning ("File \"%s\" doesn't exist.", filename);

                    return false;
                }

                FileInfo info = file.query_info (FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);
                int id = file_requests.size;
                uint64 size = (uint64)info.get_size ();
                string name = file.get_basename ();

                debug ("File loaded: #%i -> %s[%s Bytes]", id, name, size.to_string ());

                file_requests.@set (id, { (uint16)id, size, name, filename, false });
            }
        } catch (Error e) {
            warning ("Can't load files: %s", e.message);

            return false;
        }

        return true;
    }

    private void send_initialisation (string client_name) {
        uint8[] package = {};
        package += (uint8)Application.PROTOCOL_VERSION;

        for (int i = 0; i < client_name.data.length; i++) {
            package += client_name.data[i];
        }

        send_package (package);
    }

    private void send_request () {
        file_requests.@foreach ((entry) => {
            FileRequest file_request = entry.value;

            uint8[] package = {};
            package += (entry.key == file_requests.size - 1 ? 1 : 0);
            package += (uint8)(file_request.id >> 8) & 0xff;
            package += (uint8)file_request.id & 0xff;
            package += (uint8)(file_request.size >> 32) & 0xff;
            package += (uint8)(file_request.size >> 24) & 0xff;
            package += (uint8)(file_request.size >> 16) & 0xff;
            package += (uint8)(file_request.size >> 8) & 0xff;
            package += (uint8)file_request.size & 0xff;

            for (int i = 0; i < file_request.name.data.length; i++) {
                package += file_request.name.data[i];
            }

            send_package (package);

            return true;
        });
    }

    private bool receive_confirmation () {
        uint8[]? package = receive_package ();

        if (package == null) {
            return false;
        }

        if (package[0] != 1) {
            update_state (ClientState.REJECTED);

            debug ("Transmission rejected.");

            return true;
        }

        update_state (ClientState.SENDING_DATA);

        for (int i = 1; i < package.length - 1; i++) {
            uint16 id = (package[i] << 8) +
                        package[++i];

            if (file_requests.has_key (id)) {
                FileRequest file_request = file_requests.@get (id);
                file_request.accepted = true;

                debug ("File \"%s\" has been accepted.", file_request.name);

                file_requests.@set (id, file_request);
            }
        }

        return true;
    }

    private bool send_data () {
        uint16 files_sent = 0;

        file_requests.@foreach ((entry) => {
            FileRequest file_request = entry.value;

            File file = File.new_for_path (file_request.filename);

            if (!file.query_exists ()) {
                warning ("File \"%s\" doesn't exist anymore.", file_request.filename);

                return false;
            }

            send_package ({ (uint8)((file_request.id >> 8) & 0xff),
                            (uint8)(file_request.id & 0xff) });

            try {
                debug ("Opening file \"%s\"...", file_request.filename);

                InputStream input_stream = file.open_readwrite ().input_stream;

                uint64 total_size = file_request.size;
                uint64 bytes_sent = 0;

                while (bytes_sent < total_size) {
                    uint16 next_size = (uint16)(total_size - bytes_sent > uint16.MAX ? uint16.MAX : total_size - bytes_sent);
                    uint8[] package = new uint8[next_size];

                    input_stream.read (package);

                    send_package (package);
                }

                input_stream.close ();

                files_sent++;

                return true;
            } catch (Error e) {
                warning ("Sending file \"%s\" failed: %s", file_request.filename, e.message);

                return false;
            }
        });

        return (files_sent == file_requests.size);
    }

    private void update_state (ClientState state) {
        debug ("State changed to %s", state.to_string ());

        this.state = state;
        state_changed (state);
    }
}