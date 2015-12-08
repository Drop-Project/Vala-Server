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

/**
 * This class represents a connection to the daemon to access information
 * about running transmissions, start new transmissions and and list available
 * transmission partners.
 */
public class Drop.Session : Object {
    /**
     * Is called when a new incoming transmission has been detected.
     *
     * @param incoming_transmission The interface for controlling the transmission.
     */
    public signal void new_incoming_transmission (IncomingTransmission incoming_transmission);

    /**
     * Is called when a new outgoing transmission has been started.
     *
     * @param outgoing_transmission The interface for controlling the transmission.
     */
    public signal void new_outgoing_transmission (OutgoingTransmission outgoing_transmission);

    /**
     * Is called when a new transmission partner has been detected.
     *
     * @param transmission_partner The detected transmission partner.
     */
    public signal void transmission_partner_added (TransmissionPartner transmission_partner);

    /**
     * Is called when a transmission partner has disappeared.
     *
     * @param name The name of the transmission partner.
     */
    public signal void transmission_partner_removed (string name);

    private DaemonBus daemon_bus;

    private Gee.HashMap<string, IncomingTransmission> incoming_transmissions;
    private Gee.HashMap<string, OutgoingTransmission> outgoing_transmissions;

    /**
     * Creates a new Session.
     */
    public Session () {
        incoming_transmissions = new Gee.HashMap<string, IncomingTransmission> ();
        outgoing_transmissions = new Gee.HashMap<string, OutgoingTransmission> ();

        connect_dbus ();
        load_transmissions ();
        connect_signals ();
    }

    /**
     * Returns a list of the available transmission partners.
     *
     * @param show_myself Sets if the list should contain the own server.
     * @return An array of detected transmission partners.
     */
    public TransmissionPartner[] get_transmission_partners (bool show_myself) throws IOError {
        return daemon_bus.get_transmission_partners (show_myself);
    }

    /**
     * Returns a list of the running incoming transmissions.
     *
     * @return An array of incoming transmissions.
     */
    public IncomingTransmission[] get_incoming_transmissions () throws IOError {
        return incoming_transmissions.values.to_array ();
    }

    /**
     * Returns a list of the running outgoing transmissions.
     *
     * @return An array of outgoing transmissions.
     */
    public OutgoingTransmission[] get_outgoing_transmissions () throws IOError {
        return outgoing_transmissions.values.to_array ();
    }

    /**
     * Starts a new outgoing transmisson.
     *
     * @param hostname The hostname or ip-address to connect to.
     * @param port The port of the service.
     * @param filenames A list of filenames that will be requested for transmission.
     * @param use_tls Sets if the choosen port requires an encrypted connection.
     * @return Path to the transmission's dbus-interface. Can be used to identify the new transmission after the connection has been established.
     */
    public string start_transmission (string hostname, uint16 port, string[] filenames, bool use_tls = true) throws IOError {
        return daemon_bus.start_outgoing_transmission (hostname, port, filenames, use_tls);
    }

    private void connect_dbus () {
        try {
            daemon_bus = Bus.get_proxy_sync (BusType.SESSION, "org.dropd", "/org/dropd");
        } catch (Error e) {
            warning ("Connecting to drop daemon failed: %s", e.message);
        }
    }

    private void connect_signals () {
        daemon_bus.new_incoming_transmission.connect ((interface_path) => {
            register_incoming_transmission (interface_path);
        });

        daemon_bus.new_outgoing_transmission.connect ((interface_path) => {
            register_outgoing_transmission (interface_path);
        });

        daemon_bus.transmission_partner_added.connect ((transmission_partner) => transmission_partner_added (transmission_partner));
        daemon_bus.transmission_partner_removed.connect ((name) => transmission_partner_removed (name));
    }

    private void load_transmissions () {
        try {
            foreach (string interface_path in daemon_bus.get_incoming_transmissions ()) {
                register_incoming_transmission (interface_path);
            }

            foreach (string interface_path in daemon_bus.get_outgoing_transmissions ()) {
                register_outgoing_transmission (interface_path);
            }
        } catch (Error e) {
            warning ("Loading running transmissions failed: %s", e.message);
        }
    }

    private void register_incoming_transmission (string interface_path) {
        IncomingTransmission incoming_transmission = new IncomingTransmission (interface_path);

        incoming_transmissions.@set (interface_path, incoming_transmission);

        new_incoming_transmission (incoming_transmission);
    }

    private void register_outgoing_transmission (string interface_path) {
        OutgoingTransmission outgoing_transmission = new OutgoingTransmission (interface_path);

        outgoing_transmissions.@set (interface_path, outgoing_transmission);

        new_outgoing_transmission (outgoing_transmission);
    }
}