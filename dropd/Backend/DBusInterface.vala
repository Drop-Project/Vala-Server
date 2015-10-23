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
public class dropd.Backend.DBusInterface : Object {
    public signal void new_incoming_transmission (string interface_path);
    public signal void new_outgoing_transmission (string interface_path);
    public signal void transmission_partners_changed ();

    private Server server;
    private ServiceBrowser service_browser;

    private uint transmission_counter = 0;

    public DBusInterface (Server server, ServiceBrowser service_browser) {
        this.server = server;
        this.service_browser = service_browser;

        connect_signals ();
    }

    public ServiceBrowser.TransmissionPartner[] get_transmission_partners (bool show_myself = true) {
        return service_browser.get_transmission_partners (show_myself);
    }

    public string start_outgoing_transmission (string hostname, string[] filenames) {
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
                    debug ("Trying to connect to %s...", address.to_string ());

                    connection = connect_to_address (address);

                    if (connection != null) {
                        break;
                    }
                }

                if (connection == null) {
                    debug ("Connecting to host failed. Giving up.");
                } else {
                    debug ("Connection established.");

                    OutgoingTransmission protocol_implementation = new OutgoingTransmission (connection, files);

                    uint interface_id = Bus.own_name (BusType.SESSION, "org.dropd.OutgoingTransmission", BusNameOwnerFlags.NONE, (dbus_connection) => {
                        try {
                            dbus_connection.register_object (interface_path, protocol_implementation);
                            new_outgoing_transmission (interface_path);

                            debug ("DBus interface %s registered.", interface_path);
                        } catch (Error e) {
                            warning ("Registering DBus interface %s failed: %s", interface_path, e.message);
                        }
                    }, null, () => {
                        warning ("Could not aquire DBus name.");
                    });

                    protocol_implementation.protocol_failed.connect ((error_message) => {
                        warning ("Protocol failed: %s", error_message);

                        /* Close connection if possible/necessary */
                        try {
                            connection.close ();

                            warning ("Connection closed.");
                        } catch {}

                        /* Close DBus interface */
                        Bus.unown_name (interface_id);

                        debug ("DBus interface %s removed.", interface_path);
                    });
                }
            } catch (Error e) {
                warning ("Resolving hostname \"%s\" failed: %s", hostname, e.message);
            }

            return 0;
        });

        return interface_path;
    }

    private SocketConnection? connect_to_address (InetAddress address) {
        try {
            SocketClient client = new SocketClient ();
            client.event.connect (on_client_event);
            client.timeout = 10;
            client.tls = true;

            return client.connect (new InetSocketAddress (address, Application.PORT));
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
        server.new_transmission_interface_registered.connect ((interface_path) => new_incoming_transmission (interface_path));
    }
}