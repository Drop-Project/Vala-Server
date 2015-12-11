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

/**
 * This class represents an incoming transmission used to receive files
 * that were sent to you.
 */
public class Drop.IncomingTransmission : Object {
    private IncomingTransmissionBus transmission_bus;

    /**
     * Is called when an error in the protocol implementation occours.
     *
     * @param error_message The translated error message that should be displayed to the user.
     */
    public signal void protocol_failed (string error_message);

    /**
     * Is called when the state of the transmission changes.
     *
     * @param state The new state of the transmission.
     */
    public signal void state_changed (ServerState state);

    /**
     * Is called when the receiving progress of the files updates.
     *
     * @param bytes_received The count of received bytes.
     * @param total_size The total size of the current sending file.
     */
    public signal void progress_changed (uint64 bytes_received, uint64 total_size);

    /**
     * Is called when a file has been received.
     *
     * @param id The id of the received file.
     * @param filename The filename the file has been saved to.
     */
    public signal void file_received (uint id, string filename);

    /**
     * The dbus-path of the current transmission.
     */
    public string interface_path { get; construct; }

    /**
     * Creates a new interface for the dbus-interface of an incoming
     * transmission.
     *
     * @param interface_path The path of the dbus-interface.
     */
    public IncomingTransmission (string interface_path) {
        Object (interface_path: interface_path);

        connect_dbus ();
        connect_signals ();
    }

    /**
     * Lists the requested files for the transmission.
     *
     * @return A list of file requests.
     */
    public IncomingFileRequest[] get_file_requests () throws IOError {
        return transmission_bus.get_file_requests ();
    }

    /**
     * Rejects the whole transmission.
     */
    public void reject_transmission () throws IOError {
        transmission_bus.reject_transmission ();
    }

    /**
     * Accepts the transmission.
     *
     * @param ids The accepted file-ids.
     */
    public void accept_transmission (uint16[] ids) throws IOError {
        transmission_bus.accept_transmission (ids);
    }

    /**
     * Cancels the transmission.
     */
    public void cancel () throws IOError {
        transmission_bus.cancel ();
    }

    /**
     * Returns if the current connection is encrypted.
     *
     * @return The encryption state of the transmission.
     */
    public bool get_is_secure () throws IOError {
        return transmission_bus.get_is_secure ();
    }

    /**
     * Returns the current protocol state.
     *
     * @return The current state.
     */
    public ServerState get_state () throws IOError {
        return transmission_bus.get_state ();
    }

    /**
     * Returns the used protocol version of the connected client.
     *
     * @return The protocol version.
     */
    public uint8 get_client_version () throws IOError {
        return transmission_bus.get_client_version ();
    }

    /**
     * Returns the display name of the connected client.
     *
     * @return The name of the client.
     */
    public string get_client_name () throws IOError {
        return transmission_bus.get_client_name ();
    }

    private void connect_dbus () {
        try {
            transmission_bus = Bus.get_proxy_sync (BusType.SESSION, "org.dropd.IncomingTransmission", interface_path);
        } catch (Error e) {
            warning ("Connecting to incoming transmission failed: %s", e.message);
        }
    }

    private void connect_signals () {
        transmission_bus.protocol_failed.connect ((error_message) => protocol_failed (error_message));
        transmission_bus.state_changed.connect ((state) => state_changed (state));
        transmission_bus.progress_changed.connect ((bytes_received, total_size) => progress_changed (bytes_received, total_size));
        transmission_bus.file_received.connect ((id, filename) => file_received (id, filename));
    }
}