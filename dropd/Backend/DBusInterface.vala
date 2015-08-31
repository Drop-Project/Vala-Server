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
    public signal void new_transmission_request (string interface_path);
    public signal void transmission_partners_changed ();

    private Server server;
    private ServiceBrowser service_browser;

    public DBusInterface (Server server, ServiceBrowser service_browser) {
        this.server = server;
        this.service_browser = service_browser;

        connect_signals ();
    }

    private void connect_signals () {
        server.new_transmission_interface_registered.connect ((interface_path) => new_transmission_request (interface_path));
    }

    public ServiceBrowser.TransmissionPartner[] get_transmission_partners () {
        return service_browser.get_transmission_partners ();
    }
}