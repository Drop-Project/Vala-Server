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

public class DropDialog.Application : Granite.Application {
    construct {
        /* App-Properties */
        program_name = "Drop-Dialog";
        exec_name = "drop-dialog";

        /* Build-Properties */
        build_data_dir = config.DATADIR;
        build_pkg_data_dir = config.PKGDATADIR;
        build_release_name = config.RELEASE_NAME;
        build_version = config.VERSION;
        build_version_info = config.VERSION_INFO;
    }

    public Application () {
        Object (application_id: "org.pantheon.drop.dialog", flags : (ApplicationFlags.HANDLES_COMMAND_LINE |
                                                                     ApplicationFlags.HANDLES_OPEN |
                                                                     ApplicationFlags.NON_UNIQUE));

        /* Debug service */
        Granite.Services.Logger.initialize ("drop-dialog");
    }

    public override int command_line (ApplicationCommandLine command_line) {
        if (this.get_windows () != null) {
            this.get_windows ().data.present ();

            return 1;
        }

        if (!Thread.supported ()) {
            critical ("Threading is not supported by this system.");

            return 1;
        }

        debug ("Starting drop dialog...");

        MainWindow main_window = new MainWindow ();
        main_window.show_all ();

        this.add_window (main_window);

        Gtk.main ();

        return 0;
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        Application application = new Application ();

        return application.run (args);
    }
}