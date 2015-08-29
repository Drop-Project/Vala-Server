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

public class dropd.Application : Granite.Application {
    /*
     * These constants should be kept up-to-date.
     *
     * The protocol version should be incremented with any
     * protocol modification that breaks the backward compatibility.
     * Clients are using this field to decide, if they are compatible
     * to the server.
     */
    public static const int PROTOCOL_VERSION = 1;

    /*
     * This field describes the implementation of the drop protocol
     * for debugging reasons. Don't copy the string 1:1 to a port or
     * modification of this server.
     */
    public static const string PROTOCOL_IMPLEMENTATION = "official vala drop daemon";

    private Backend.SettingsManager settings_manager;
    private Backend.ServiceProvider service_provider;

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
        Object (application_id: "org.pantheon.drop", flags : ApplicationFlags.IS_SERVICE);

        /* Debug service */
        Granite.Services.Logger.initialize ("dropd");
    }

    public override void startup () {
        base.startup ();

        debug ("Starting drop daemon...");

        settings_manager = new Backend.SettingsManager ();
        service_provider = new Backend.ServiceProvider (settings_manager);

        new MainLoop ().run ();
    }

    public static void main (string[] args) {
        Gtk.init (ref args);

        var application = new Application ();
        application.run (args);
    }
}