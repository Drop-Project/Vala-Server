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

[DBus (name = "org.dropd")]
public class DropDaemon.Backend.DBusInterface : Object {
    public signal void new_incoming_transmission (string interface_path);
    public signal void new_outgoing_transmission (string interface_path);
    public signal void transmission_partner_added (ServiceBrowser.TransmissionPartner transmission_partner);
    public signal void transmission_partner_removed (string name);

    private Server server;
    private SettingsManager settings_manager;
    private ServiceBrowser service_browser;

    private DBusConnection dbus_connection;

    private Gee.ArrayList<string> incoming_transmissions;
    private Gee.ArrayList<string> outgoing_transmissions;

    private uint transmission_counter = 0;

    public DBusInterface (Server server, SettingsManager settings_manager, ServiceBrowser service_browser) {
        this.server = server;
        this.settings_manager = settings_manager;
        this.service_browser = service_browser;

        incoming_transmissions = new Gee.ArrayList<string> ();
        outgoing_transmissions = new Gee.ArrayList<string> ();

        Bus.own_name (BusType.SESSION, "org.dropd.OutgoingTransmission", BusNameOwnerFlags.NONE, (dbus_connection) => {
            this.dbus_connection = dbus_connection;
        }, null, () => {
            warning ("Could not aquire DBus name org.dropd.OutgoingTransmission");
        });

        connect_signals ();
    }

    public ServiceBrowser.TransmissionPartner[] get_transmission_partners (bool show_myself = true) {
        return service_browser.get_transmission_partners (show_myself);
    }

    public string[] get_incoming_transmissions () {
        return incoming_transmissions.to_array ();
    }

    public string[] get_outgoing_transmissions () {
        return outgoing_transmissions.to_array ();
    }

    public string start_outgoing_transmission (string hostname, uint16 port, string[] filenames, bool require_tls) {
        string interface_path = "/org/dropd/OutgoingTransmission%u".printf (transmission_counter++);
        string[] files = filenames;

        new Thread<int> (null, () => {
            debug ("Resolving \"%s\"...", hostname);

            Resolver resolver = Resolver.get_default ();

            try {
                List<InetAddress> addresses = resolver.lookup_by_name (hostname);
                SocketConnection? connection = null;

                /* Try all addresses until one works */
                foreach (InetAddress address in addresses) {
                    debug ("Trying to connect to %s:%u...", address.to_string (), port);

                    connection = connect_to_address (address, port, require_tls);

                    if (connection != null) {
                        break;
                    }
                }

                if (connection == null) {
                    debug ("Connecting to host failed. Giving up.");
                } else {
                    debug ("Connection established.");

                    OutgoingTransmission protocol_implementation = new OutgoingTransmission (connection,
                                                                                             settings_manager.server_name.strip () == "" ? Environment.get_host_name () : settings_manager.server_name,
                                                                                             files,
                                                                                             require_tls);

                    try {
                        uint object_id = dbus_connection.register_object (interface_path, protocol_implementation);

                        outgoing_transmissions.add (interface_path);
                        new_outgoing_transmission (interface_path);

                        debug ("DBus interface %s registered.", interface_path);

                        protocol_implementation.state_changed.connect ((state) => {
                            if (state != OutgoingTransmission.ClientState.FAILURE &&
                                state != OutgoingTransmission.ClientState.REJECTED &&
                                state != OutgoingTransmission.ClientState.CANCELED &&
                                state != OutgoingTransmission.ClientState.FINISHED) {
                                return;
                            }

                            /* Close connection if possible/necessary */
                            try {
                                connection.close ();

                                debug ("Connection closed.");
                            } catch {}

                            /* Close DBus interface */
                            dbus_connection.unregister_object (object_id);

                            outgoing_transmissions.remove (interface_path);

                            debug ("DBus interface %s removed.", interface_path);
                        });
                    } catch (Error e) {
                        warning ("Registering DBus interface %s failed: %s", interface_path, e.message);
                    }
                }
            } catch (Error e) {
                warning ("Resolving hostname \"%s\" failed: %s", hostname, e.message);
            }

            return 0;
        });

        return interface_path;
    }

    private SocketConnection? connect_to_address (InetAddress address, uint16 port, bool require_tls) {
        try {
            Cancellable cancellable = new Cancellable ();
            SocketClient client = new SocketClient ();
            client.event.connect (on_client_event);
            client.tls = require_tls;

            /*
             * We need to do the timeout stuff manually, because the built-in
             * timeout functionalities affect the connection as well.
             */
            Timeout.add (10 * 1000, () => {
                cancellable.cancel ();

                return false;
            });

            return client.connect (new InetSocketAddress (address, port), cancellable);
        } catch (Error e) {
            warning ("Connecting to address failed: %s", e.message);

            return null;
        }
    }

    private void on_client_event (SocketClientEvent event, SocketConnectable connectable, IOStream? connection) {
        if (event == SocketClientEvent.TLS_HANDSHAKING) {
            ((TlsConnection)connection).accept_certificate.connect ((peer_cert, errors) => {
                /*
                 * Accept all certificates for now.
                 * FIXME: Do further tests in the future for higher security.
                 */
                return true;
            });
        }
    }

    private void connect_signals () {
        server.new_transmission_interface_registered.connect ((interface_path) => {
            incoming_transmissions.add (interface_path);
            new_incoming_transmission (interface_path);
        });

        server.transmission_interface_removed.connect ((interface_path) => {
            incoming_transmissions.remove (interface_path);
        });

        service_browser.transmission_partner_added.connect ((transmission_partner) => transmission_partner_added (transmission_partner));
        service_browser.transmission_partner_removed.connect ((name) => transmission_partner_removed (name));
    }
}