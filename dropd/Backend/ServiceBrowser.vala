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

public class dropd.Backend.ServiceBrowser : Object {
    public struct TransmissionPartner {
        string hostname;
        uint16 port;
        int protocol_version;
        string protocol_implementation;
        string display_name;
        bool server_enabled;
    }

    /* FIXME: This is a workaround to enable the use of the struct as generic type. */
    private class TransmissionPartnerEntry : Object {
        public TransmissionPartner transmission_partner { get; construct set; }

        public TransmissionPartnerEntry (TransmissionPartner transmission_partner) {
            Object (transmission_partner: transmission_partner);
        }
    }

    private static const string SERVICE_TYPE = "_drop._tcp";

    private static const string SERVICE_FIELD_PROTOCOL_VERSION = "protocol-version";
    private static const string SERVICE_FIELD_PROTOCOL_IMPLEMENTATION = "protocol-implementation";
    private static const string SERVICE_FIELD_DISPLAY_NAME = "display-name";
    private static const string SERVICE_FIELD_SERVER_ENABLED = "server-enabled";

    private Gee.HashMap<string, TransmissionPartnerEntry> transmission_partners;

    public Avahi.Client client { private get; construct; }

    private Avahi.ServiceBrowser browser;

    private string hostname;

    public ServiceBrowser (Avahi.Client client) {
        Object (client: client);

        transmission_partners = new Gee.HashMap<string, TransmissionPartnerEntry> ();

        browser = new Avahi.ServiceBrowser (SERVICE_TYPE);

        hostname = Utils.get_hostname ();

        connect_signals ();
    }

    public TransmissionPartner[] get_transmission_partners () {
        TransmissionPartner[] partners = {};

        transmission_partners.@foreach ((entry) => {
            partners += entry.value.transmission_partner;

            return true;
        });

        return partners;
    }

    private void connect_signals () {
        client.state_changed.connect ((state) => {
            switch (state) {
                case Avahi.ClientState.S_RUNNING:
                    try {
                        browser.attach (client);
                    } catch (Error e) {
                        critical ("Cannot attach client to browser: %s", e.message);
                    }

                    break;
            }
        });

        browser.new_service.connect ((@interface, protocol, name, type, domain, flags) => {
            if (name == hostname || transmission_partners.has_key (name)) {
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

                transmission_partners.set (name, new TransmissionPartnerEntry ({
                    hostname,
                    port,
                    int.parse (get_txt_field_value (txt, SERVICE_FIELD_PROTOCOL_VERSION)),
                    get_txt_field_value (txt, SERVICE_FIELD_PROTOCOL_IMPLEMENTATION),
                    get_txt_field_value (txt, SERVICE_FIELD_DISPLAY_NAME),
                    get_txt_field_value (txt, SERVICE_FIELD_SERVER_ENABLED) == "true"
                }));
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