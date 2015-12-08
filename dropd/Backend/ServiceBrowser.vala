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

public class DropDaemon.Backend.ServiceBrowser : Object {
    public struct TransmissionPartner {
        string name;
        string hostname;
        uint16 port;
        uint16 unencrypted_port;
        int protocol_version;
        string protocol_implementation;
        string display_name;
        bool server_enabled;
    }

    private static const string SERVICE_TYPE = "_drop._tcp";

    private static const string SERVICE_FIELD_PROTOCOL_VERSION = "protocol-version";
    private static const string SERVICE_FIELD_PROTOCOL_IMPLEMENTATION = "protocol-implementation";
    private static const string SERVICE_FIELD_UNENCRYPTED_PORT = "unencrypted-port";
    private static const string SERVICE_FIELD_DISPLAY_NAME = "display-name";
    private static const string SERVICE_FIELD_SERVER_ENABLED = "server-enabled";

    public signal void transmission_partner_added (TransmissionPartner transmission_partner);
    public signal void transmission_partner_removed (string name);

    public Avahi.Client client { private get; construct; }

    private Gee.HashMap<string, TransmissionPartner? > transmission_partners;

    private Avahi.ServiceBrowser browser;

    public ServiceBrowser (Avahi.Client client) {
        Object (client : client);

        transmission_partners = new Gee.HashMap<string, TransmissionPartner? > ();

        browser = new Avahi.ServiceBrowser (SERVICE_TYPE);

        connect_signals ();
    }

    public TransmissionPartner[] get_transmission_partners (bool show_myself = true) {
        TransmissionPartner[] partners = {};

        transmission_partners.@foreach ((entry) => {
            if (!show_myself && entry.value.hostname.down ().replace (".local", "") == Environment.get_host_name ().down ()) {
                return true;
            }

            partners += entry.value;

            return true;
        });

        return partners;
    }

    private void connect_signals () {
        client.state_changed.connect ((state) => {
            switch (state) {
                case Avahi.ClientState.S_RUNNING :
                    try {
                        browser.attach (client);
                    } catch (Error e) {
                        critical ("Cannot attach client to browser: %s", e.message);
                    }

                    break;
            }
        });

        browser.new_service.connect ((@interface, protocol, name, type, domain, flags) => {
            if (transmission_partners.has_key (name)) {
                return;
            }

            debug ("Service \"%s\" detected.", name);

            Avahi.ServiceResolver resolver = new Avahi.ServiceResolver (interface, protocol, name, type, domain, Avahi.Protocol.UNSPEC);

            resolver.failure.connect ((error) => {
                warning ("Resolving service failed: %s", error.message);
            });

            resolver.found.connect ((@interface, protocol, name, type, domain, hostname, address, port, txt, flags) => {
                if (txt == null) {
                    warning ("Cannot access service configuration fields.");

                    return;
                }

                TransmissionPartner transmission_partner = {
                    name,
                    hostname,
                    port,
                    (uint16)uint64.parse (get_txt_field_value (txt, SERVICE_FIELD_UNENCRYPTED_PORT)),
                    int.parse (get_txt_field_value (txt, SERVICE_FIELD_PROTOCOL_VERSION)),
                    get_txt_field_value (txt, SERVICE_FIELD_PROTOCOL_IMPLEMENTATION),
                    get_txt_field_value (txt, SERVICE_FIELD_DISPLAY_NAME),
                    get_txt_field_value (txt, SERVICE_FIELD_SERVER_ENABLED) == "true"
                };

                transmission_partners.@set (name, transmission_partner);
                transmission_partner_added (transmission_partner);
            });

            try {
                resolver.attach (client);
            } catch (Error e) {
                critical ("Cannot attach client to resolver: %s", e.message);
            }

            /* FIXME: We need to make sure that the object is unreferenced later. Calling unref () triggers errors. */
            resolver.ref ();
        });

        browser.removed_service.connect ((@interface, protocol, name, type, domain, flags) => {
            if (!transmission_partners.has_key (name)) {
                return;
            }

            debug ("Service \"%s\" disappeared.", name);

            transmission_partners.unset (name);
            transmission_partner_removed (name);
        });

        browser.failure.connect ((error) => {
            warning ("Failure while browsing for services: %s", error.message);
        });
    }

    private string get_txt_field_value (Avahi.StringList txt, string field) {
        string key;
        char[] value;

        unowned Avahi.StringList entry = txt.find (field);

        if (entry.length () > 0) {
            entry.get_pair (out key, out value);

            return (string)value;
        }

        return "";
    }
}