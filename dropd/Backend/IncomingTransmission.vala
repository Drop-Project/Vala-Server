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

[DBus (name = "org.dropd.IncomingTransmission")]
public class DropDaemon.Backend.IncomingTransmission : ProtocolImplementation {
    public enum ServerState {
        AWAITING_INITIALISATION,
        SENDING_INITIALISATION,
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
    public signal void progress_changed (uint64 bytes_received, uint64 total_size);
    public signal void file_received (uint id, string filename);

    private bool is_secure = false;
    private ServerState state = ServerState.AWAITING_INITIALISATION;

    private uint8 client_version;
    private string client_name;
    private Gee.HashMap<uint16, FileRequest? > file_requests;

    public IncomingTransmission (IOStream connection, string server_name, bool is_secure) {
        base (connection.input_stream, connection.output_stream);

        this.is_secure = is_secure;

        new Thread<int> (null, () => {
            if (!receive_initialisation ()) {
                protocol_failed (_("Receiving initialisation failed."));
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.SENDING_INITIALISATION);

            if (!send_initialisation (server_name)) {
                protocol_failed (_("Sending initialisation failed."));
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
            if (!send_confirmation (false)) {
                protocol_failed (_("Sending confirmation failed."));
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.REJECTED);

            return 0;
        });
    }

    public void accept_transmission (uint16[] ids) {
        if (state != ServerState.NEEDS_CONFIRMATION) {
            return;
        }

        update_state (ServerState.SENDING_CONFIRMATION);

        uint16[] accepted_ids = ids;

        new Thread<int> (null, () => {
            remember_accepted_ids (accepted_ids);

            if (!send_confirmation (true, accepted_ids)) {
                protocol_failed (_("Sending confirmation failed."));
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.RECEIVING_DATA);

            if (!receive_data ()) {
                protocol_failed ("Receiving data failed.");
                update_state (ServerState.FAILURE);

                return 0;
            }

            update_state (ServerState.FINISHED);

            return 0;
        });
    }

    public void cancel () {
        debug ("Protocol canceled.");

        cancellable.cancel ();

        update_state (ServerState.CANCELED);
    }

    public bool get_is_secure () {
        return is_secure;
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
        uint8[]? package = receive_package (2);

        if (package == null) {
            return false;
        }

        client_version = package[0];

        package.move (1, 0, package.length);

        client_name = (string)package;

        return true;
    }

    private bool send_initialisation (string server_name) {
        uint8[] package = {};
        package += (uint8)Application.PROTOCOL_VERSION;

        for (int i = 0; i < server_name.data.length; i++) {
            package += server_name.data[i];
        }

        return send_package (package);
    }

    private bool receive_request () {
        file_requests = new Gee.HashMap<uint16, FileRequest? > ();
        bool last_file = false;

        do {
            uint8[]? package = receive_package (9);

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
            string name = ((string)package).replace ("..", "");

            debug ("File request received: #%u -> %s[%s Bytes]", id, name, size.to_string ());

            file_requests.@set (id, { id, size, name, false });
        } while (!last_file);

        return true;
    }

    private void remember_accepted_ids (uint16[] accepted_ids) {
        foreach (uint16 id in accepted_ids) {
            if (file_requests.has_key (id)) {
                FileRequest file_request = file_requests.@get (id);
                file_request.accepted = true;

                debug ("File \"%s\" has been accepted.", file_request.name);

                file_requests.@set (id, file_request);
            }
        }
    }

    private bool send_confirmation (bool accepted, uint16[]? accepted_ids = null) {
        bool accept = (accepted && accepted_ids != null);

        uint8[] package = {};
        package += (accept ? 1 : 0);

        if (accept) {
            foreach (uint16 id in accepted_ids) {
                package += (uint8)(id >> 8) & 0xff;
                package += (uint8)id & 0xff;
            }
        }

        return send_package (package);
    }

    private bool receive_data () {
        string target_directory = Environment.get_user_special_dir (UserDirectory.DOWNLOAD);

        uint16 files_received = 0;
        uint16 files_expected = 0;

        file_requests.@foreach ((entry) => {
            if (entry.value.accepted) {
                files_expected++;
            }

            return true;
        });

        while (files_received < files_expected) {
            uint8[]? package = receive_package (2);

            if (package == null) {
                return false;
            }

            uint16 id = (package[0] << 8) +
                        package[1];

            if (!file_requests.has_key (id)) {
                warning ("Received file #%i not requested.", id);

                return false;
            }

            FileRequest file_request = file_requests.@get (id);

            if (!file_request.accepted) {
                warning ("Received file #%i not accepted.", id);

                return false;
            }

            File file = File.new_for_path ("%s/%s".printf (target_directory, file_request.name));
            int tries = 0;

            /* Automatically manipulate name until target file isn't already existent. */
            while (file.query_exists (cancellable)) {
                file = File.new_for_path ("%s/%s.%i".printf (target_directory, file_request.name, ++tries));
            }

            try {
                debug ("Creating file \"%s\"...", file.get_path ());

                OutputStream output_stream = file.create (FileCreateFlags.NONE, cancellable);

                debug ("Receiving...");

                uint64 total_size = file_request.size;
                uint64 bytes_received = 0;

                while (bytes_received < total_size) {
                    uint64 next_size = (total_size - bytes_received);

                    if (next_size > MAX_PACKAGE_LENGTH) {
                        next_size = MAX_PACKAGE_LENGTH;
                    }

                    uint8[]? next_package = receive_package ((uint16)next_size);

                    if (next_package == null) {
                        return false;
                    }

                    if (output_stream.write (next_package, cancellable) != next_package.length) {
                        warning ("Writing data to \"%s\" failed.", file.get_path ());

                        return false;
                    }

                    bytes_received += next_package.length;
                    progress_changed (bytes_received, total_size);
                }

                output_stream.close (cancellable);

                files_received++;
                file_received (id, file.get_path ());
            } catch (Error e) {
                warning ("Receiving file \"%s\" failed: %s", file_request.name, e.message);

                return false;
            }
        }

        return (files_received == files_expected);
    }

    private void update_state (ServerState state) {
        debug ("State changed to %s", state.to_string ());

        this.state = state;
        state_changed (state);
    }
}