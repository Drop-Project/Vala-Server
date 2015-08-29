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

public class dropd.Backend.ServiceProvider : Object {
    private static const string SERVICE_TYPE = "_drop._tcp";
    private static const uint16 SERVICE_PORT = 7431;

    private Avahi.Client client;
    private Avahi.EntryGroup entry_group;

    public ServiceProvider () {
        client = new Avahi.Client ();
        entry_group = new Avahi.EntryGroup ();

        connect_signals ();

        try {
            client.start ();
        } catch (Error e) {
            warning ("Connecting to Avahi failed: %s", e.message);
        }
    }

    private void connect_signals () {
        client.state_changed.connect ((state) => {
            switch (state) {
                case Avahi.ClientState.S_RUNNING:
                    try {
                        entry_group.attach (client);
                    } catch (Error e) {
                        warning ("Cannot attach client to entry group: %s", e.message);
                    }

                    break;
            }
        });

        entry_group.state_changed.connect ((state) => {
            switch (state) {
                case Avahi.EntryGroupState.UNCOMMITED:
                    try {
                        entry_group.add_service (Utils.get_hostname (), SERVICE_TYPE, SERVICE_PORT);
                        entry_group.commit ();
                    } catch (Error e) {
                        warning ("Registering service failed: %s", e.message);
                    }

                    break;
                case Avahi.EntryGroupState.ESTABLISHED:
                    debug ("Drop Service registered.");

                    break;
            }
        });
    }
}