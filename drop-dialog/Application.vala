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

public class DropDialog.Application : Granite.Application {
    private static const OptionEntry[] OPTIONS = {
        { "show-myself", 'm', 0, OptionArg.NONE, null, "List own drop server", null },
        { null }
    };

    private bool show_myself = false;

    private Gee.ArrayList<string> filenames;

    private Gtk.Window? current_window = null;

    construct {
        /* App-Properties */
        application_id = "org.pantheon.drop.dialog";
        flags = (ApplicationFlags.HANDLES_COMMAND_LINE | ApplicationFlags.HANDLES_OPEN | ApplicationFlags.NON_UNIQUE);
        program_name = "Drop-Dialog";
        exec_name = "drop-dialog";

        /* Build-Properties */
        build_data_dir = config.DATADIR;
        build_pkg_data_dir = config.PKGDATADIR;
        build_release_name = config.RELEASE_NAME;
        build_version = config.VERSION;
        build_version_info = config.VERSION_INFO;

        add_main_option_entries (OPTIONS);
    }

    public Application () {
        /* Debug service */
        Granite.Services.Logger.initialize ("drop-dialog");

        filenames = new Gee.ArrayList<string> ();
    }

    protected override int command_line (ApplicationCommandLine command_line) {
        this.hold ();

        int res = process_command_line (command_line);

        this.release ();

        return res;
    }

    private int process_command_line (ApplicationCommandLine command_line) {
        if (current_window != null) {
            current_window.present ();

            return 1;
        }

        if (!Thread.supported ()) {
            critical ("Threading is not supported by this system.");

            return 1;
        }

        VariantDict options = command_line.get_options_dict ();

        if (options.contains ("show-myself")) {
            show_myself = true;
        }

        string[] args = command_line.get_arguments ();

        if (args.length > 1) {
            for (int i = 1; i < args.length; i++) {
                File file = File.new_for_path (args[i]);

                if (file.query_exists ()) {
                    filenames.add (file.get_path ());
                } else {
                    warning ("File %s doesn't exists.", args[i]);
                }
            }

            if (filenames.size == 0) {
                return 1;
            }

            show_main_window ();
        } else {
            show_file_chooser ();
        }

        return 0;
    }

    private void show_file_chooser () {
        Gtk.FileChooserDialog file_chooser = new Gtk.FileChooserDialog (_("Select the files you want to send…"),
                                                                        null,
                                                                        Gtk.FileChooserAction.OPEN,
                                                                        _("Cancel"),
                                                                        Gtk.ResponseType.CANCEL,
                                                                        _("Open"),
                                                                        Gtk.ResponseType.ACCEPT);
        file_chooser.select_multiple = true;

        current_window = file_chooser;

        if (file_chooser.run () == Gtk.ResponseType.ACCEPT) {
            foreach (File file in file_chooser.get_files ()) {
                filenames.add (file.get_path ());
            }

            file_chooser.destroy ();
            show_main_window ();

            return;
        }
    }

    private void show_main_window () {
        MainWindow main_window = new MainWindow (filenames, show_myself);

        main_window.show_all ();
        main_window.destroy.connect (() => {
            Gtk.main_quit ();
        });

        current_window = main_window;

        this.add_window (main_window);

        Gtk.main ();
    }

    public static int main (string[] args) {
        Gtk.init (ref args);

        Application application = new Application ();

        return application.run (args);
    }
}