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

namespace Drop {
    /**
     * Represents a transmission partner you can connect to.
     */
    public struct TransmissionPartner {
        /**
         * The name of the transmission partner, acting as an ID.
         */
        string name;

        /**
         * The hostname of the computer.
         */
        string hostname;

        /**
         * The port of the service. This port requires a TLS handshake.
         */
        uint16 port;

        /**
         * The unencrypted port of the service.
         * This port doesn't allow TLS, make sure that the user does not send critical
         * files using this port.
         */
        uint16 unencrypted_port;

        /**
         * The version of the protocol the server uses.
         */
        int protocol_version;

        /**
         * The name of the server's protocol implementation.
         */
        string protocol_implementation;

        /**
         * The server-name that should be displayed to the user.
         */
        string display_name;

        /**
         * If true, the server is running and accepts transmissions.
         */
        bool server_enabled;
    }

    /**
     * Represents a file request of an incoming transmission.
     */
    public struct IncomingFileRequest {
        /**
         * The id of the file.
         */
        uint16 id;

        /**
         * The file size.
         */
        uint64 size;

        /**
         * The name of the file.
         */
        string name;

        /**
         * If true, the file has been accepted.
         */
        bool accepted;
    }

    /**
     * Represents a file request of an outgoing transmission.
     */
    public struct OutgoingFileRequest {
        /**
         * The id of the file.
         */
        uint16 id;

        /**
         * The file size.
         */
        uint64 size;

        /**
         * The name of the file.
         */
        string name;

        /**
         * The filename of the file on the current system.
         */
        string filename;

        /**
         * If true, the file has been accepted by the server.
         */
        bool accepted;
    }

    /**
     * Represents the protocol state of an incoming transmission.
     */
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

    /**
     * Represents the protocol state of an outgoing transmission.
     */
    public enum ClientState {
        LOADING_FILES,
        SENDING_INITIALISATION,
        AWAITING_INITIALISATION,
        SENDING_REQUEST,
        AWAITING_CONFIRMATION,
        REJECTED,
        SENDING_DATA,
        FINISHED,
        CANCELED,
        FAILURE
    }

    [DBus (name = "org.dropd")]
    private interface DaemonBus : Object {
        public signal void new_incoming_transmission (string interface_path);
        public signal void new_outgoing_transmission (string interface_path);
        public signal void transmission_partner_added (TransmissionPartner transmission_partner);
        public signal void transmission_partner_removed (string name);

        public abstract TransmissionPartner[] get_transmission_partners (bool show_myself = true) throws IOError;
        public abstract string[] get_incoming_transmissions () throws IOError;
        public abstract string[] get_outgoing_transmissions () throws IOError;
        public abstract string start_outgoing_transmission (string hostname, uint16 port, string[] filenames, bool require_tls) throws IOError;
    }

    [DBus (name = "org.dropd.IncomingTransmission")]
    private interface IncomingTransmissionBus : Object {
        public signal void protocol_failed (string error_message);
        public signal void state_changed (ServerState state);
        public signal void progress_changed (uint64 bytes_received, uint64 total_size);
        public signal void file_received (uint id, string filename);

        public abstract IncomingFileRequest[] get_file_requests () throws IOError;
        public abstract void reject_transmission () throws IOError;
        public abstract void accept_transmission (uint16[] ids) throws IOError;
        public abstract void cancel () throws IOError;
        public abstract bool get_is_secure () throws IOError;
        public abstract ServerState get_state () throws IOError;
        public abstract uint8 get_client_version () throws IOError;
        public abstract string get_client_name () throws IOError;
    }

    [DBus (name = "org.dropd.OutgoingTransmission")]
    private interface OutgoingTransmissionBus : Object {
        public signal void protocol_failed (string error_message);
        public signal void state_changed (ClientState state);
        public signal void progress_changed (uint64 bytes_sent, uint64 total_size);
        public signal void file_sent (uint id);

        public abstract OutgoingFileRequest[] get_file_requests () throws IOError;
        public abstract void cancel () throws IOError;
        public abstract bool get_is_secure () throws IOError;
        public abstract ClientState get_state () throws IOError;
        public abstract uint8 get_server_version () throws IOError;
        public abstract string get_server_name () throws IOError;
    }
}