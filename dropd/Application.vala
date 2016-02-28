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

public class DropDaemon.Application : Granite.Application {
    /*
     * These constants should be kept up-to-date.
     *
     * The protocol version should be incremented with any
     * protocol modification that breaks the backward compatibility.
     * Clients are using this field to decide, if they are compatible
     * to the server or not.
     */
    public static const uint8 PROTOCOL_VERSION = 1;

    /*
     * This field describes the implementation of the drop protocol
     * for debugging reasons. Don't copy the string 1:1 to a port or
     * modification of this server.
     */
    public static const string PROTOCOL_IMPLEMENTATION = "official-vala";

    /*
     * These ports should be kept across all implemenations
     * to serve optimal compatibility.
     *
     * The unencrypted port is optinal and can be added to implementations
     * to allow an alternative and eventually faster transmission.
     */
    public static const uint16 PORT = 7431;
    public static const uint16 UNENCRYPTED_PORT = 7432;

    private Avahi.Client client;

    private Backend.SettingsManager settings_manager;
    private Backend.ServiceProvider service_provider;
    private Backend.ServiceBrowser service_browser;
    private Backend.Server server;
    private Backend.DBusInterface dbus_interface;

    construct {
        /* App-Properties */
        program_name = "Drop-Daemon";
        exec_name = "dropd";

        /* Build-Properties */
        build_data_dir = config.DATADIR;
        build_pkg_data_dir = config.PKGDATADIR;
        build_release_name = config.RELEASE_NAME;
        build_version = config.VERSION;
        build_version_info = config.VERSION_INFO;
    }

    public Application () {
        Object (application_id: "org.pantheon.drop.daemon", flags : ApplicationFlags.IS_SERVICE);

        /* Debug service */
        Granite.Services.Logger.initialize ("dropd");
    }

    public override void startup () {
        base.startup ();

        if (!Thread.supported ()) {
            critical ("Threading is not supported by this system.");

            return;
        }

        debug ("Starting drop daemon...");

        client = new Avahi.Client ();

        settings_manager = new Backend.SettingsManager ();
        service_provider = new Backend.ServiceProvider (client, settings_manager);
        service_browser = new Backend.ServiceBrowser (client);
        server = new Backend.Server ();
        dbus_interface = new Backend.DBusInterface (server, settings_manager, service_browser);

        try {
            client.start ();
        } catch (Error e) {
            critical ("Connecting to Avahi failed: %s", e.message);
        }

        initialize_dbus ();

        if (settings_manager.server_enabled) {
            server.start ();
        }

        connect_signals ();

        info ("Initialization finished.");

        new MainLoop ().run ();
    }

    private void initialize_dbus () {
        Bus.own_name (BusType.SESSION, "org.dropd", BusNameOwnerFlags.NONE, (dbus_connection) => {
            try {
                dbus_connection.register_object ("/org/dropd", dbus_interface);
                debug ("DBus interface /org/dropd registered.");
            } catch (Error e) {
                warning ("Registering DBus interface /org/dropd failed: %s", e.message);
            }
        }, null, () => {
            warning ("Could not aquire DBus name org.dropd");
        });
    }

    private void connect_signals () {
        settings_manager.notify["server-enabled"].connect (() => {
            if (settings_manager.server_enabled) {
                server.start ();
            } else {
                server.stop ();
            }
        });
    }

    public static void main (string[] args) {
        Gtk.init (ref args);

        Application application = new Application ();
        application.run (args);
    }
}