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
        string filename;
    }

    public signal void protocol_failed (string error_message);
    public signal void state_changed (ClientState state);

    private ClientState state = ClientState.LOADING_FILES;

    private Gee.HashMap<int, FileRequest? > file_requests;

    public OutgoingTransmission (SocketConnection connection, string[] files) {
        base (connection.input_stream, connection.output_stream);

        new Thread<int> (null, () => {
            if (!load_files (files)) {
                protocol_failed (_("Loading files failed."));

                return 0;
            }

            if (!send_request ()) {
                protocol_failed (_("Sending request failed."));

                return 0;
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
                uint32 size = (uint32)info.get_size ();
                string name = file.get_basename ();

                debug ("File loaded: #%i -> %s[%u Bytes]", id, name, size);

                file_requests.@set (id, { (uint16)id, size, name, filename });
            }
        } catch (Error e) {
            warning ("Can't load files: %s", e.message);

            return false;
        }

        return true;
    }

    private bool send_request () {
        file_requests.@foreach ((entry) => {
            FileRequest file_request = entry.value;

            uint8[] package = {};
            package += CLIENT_COMMAND_FILE_REQUEST;
            package += (entry.key == file_request.size - 1 ? 1 : 0);
            package += (uint8)(file_request.id >> 8) & 0xff;
            package += (uint8)file_request.id & 0xff;
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

        return true;
    }

    private void update_state (ClientState state) {
        this.state = state;
        state_changed (state);
    }
}