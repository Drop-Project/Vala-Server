/*
 * Copyright (c) 2015-2016 Drop Developers
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
 * Authored by: Felipe Escoto <felescoto95@hotmail.com>,
 *              Marcus Wichelmann <marcus.wichelmann@hotmail.de>
 */

/**
 * Widget that can be used to accept and reject an incoming transmission and view it's current progress.
 */
public class Drop.Widgets.IncomingTransmissionListEntry : TransmissionListEntry {
    /**
     * The transmission the entry is built on.
     */
    public IncomingTransmission transmission { get; private set; }

    private Gtk.Button accept_button;
    private Gtk.Button reject_button;

    private Gtk.Button cancel_button;

    /**
     * Creates a new incoming transmission entry.
     *
     * @param transmission Transmission to build the entry on.
     */
    public IncomingTransmissionListEntry (IncomingTransmission transmission) {
        this.transmission = transmission;

        build_ui ();
        read_state ();
        connect_signals ();
    }

    private void build_ui () {
        action_area.get_style_context ().add_class (Gtk.STYLE_CLASS_LINKED);

        accept_button = new Gtk.Button.from_icon_name ("object-select-symbolic", Gtk.IconSize.BUTTON);
        accept_button.valign = Gtk.Align.CENTER;

        reject_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.BUTTON);
        reject_button.valign = Gtk.Align.CENTER;

        cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.BUTTON);
        cancel_button.valign = Gtk.Align.CENTER;
    }

    private void read_state () {
        try {
            display_state (this.transmission.get_state ());
        } catch (Error e) {
            warning ("Reading transmission state failed: %s", e.message);
        }
    }

    private void connect_signals () {
        transmission.state_changed.connect (display_state);
        transmission.progress_changed.connect (display_progress);

        accept_button.clicked.connect (() => {
            try {
                var files = transmission.get_file_requests ();
                uint16[] ids = {};

                foreach (var file in files) {
                    ids += file.id;
                }

                transmission.accept_transmission (ids);
                accept_button.set_visible (false);
            } catch (Error e) {
                stderr.printf ("Could not accept transmition: %s", e.message);
            }
        });

        reject_button.clicked.connect (() => {
            try {
                transmission.reject_transmission ();
                this.destroy ();
            } catch (Error e) {
                stderr.printf ("Could not reject transmition: %s", e.message);
            }
        });

        cancel_button.clicked.connect (() => {
            try {
                transmission.cancel ();
                this.destroy ();
            } catch (Error e) {
                stderr.printf ("Could not cancel transmition: %s", e.message);
            }
        });
    }

    private void display_state (ServerState state) {
        switch (state) {
            case ServerState.AWAITING_INITIALISATION:
                display_awaiting_initialisation ();
                break;
            case ServerState.AWAITING_REQUEST:
                display_awaiting_request ();
                break;
            case ServerState.NEEDS_CONFIRMATION:
                display_needs_confirmation ();
                break;
            case ServerState.REJECTED:
                display_rejected ();
                break;
            case ServerState.RECEIVING_DATA:
                display_receiving_data ();
                break;
            case ServerState.FINISHED:
                display_finished ();
                break;
            case ServerState.CANCELED:
                display_canceled ();
                break;
            case ServerState.FAILURE:
                display_failure ();
                break;
        }
    }

    private void display_awaiting_initialisation () {
        set_primary_label (_("Awaiting initialisation…"));
    }

    private void display_awaiting_request () {
        set_primary_label (_("Awaiting request…"));
    }

    private void display_needs_confirmation () {
        try {
            var files = transmission.get_file_requests ();

            if (files.length == 0) {
                warning ("File list invalid.");

                this.destroy ();

                return;
            }

            if (files.length == 1) {
                display_single_file (files[0]);
            } else {
                display_multi_files (files);
            }

            action_area.add (accept_button);
            action_area.add (reject_button);
            action_area.show_all ();
        } catch (Error e) {
            warning ("Reading file request failed: %s", e.message);
        }
    }

    private void display_rejected () {
        set_secondary_label (_("Transmission rejected"));
    }

    private void display_receiving_data () {
        set_secondary_label (_("Receiving files…"));
        set_progress_visible (true);

        action_area.remove (accept_button);
        action_area.remove (reject_button);
        action_area.add (cancel_button);
        action_area.show_all ();
    }

    private void display_finished () {
        set_secondary_label (_("Done"));
        set_progress_visible (false);
    }

    private void display_canceled () {
        set_secondary_label (_("Canceled"));
        set_progress_visible (false);
    }

    private void display_failure () {
        set_secondary_label (_("Failed"));
        set_progress_visible (false);
    }

    private void display_single_file (IncomingFileRequest file) {
        set_primary_label (file.name);

        string info_text = format_size (file.size);

        try {
            info_text += _(" - From: %s").printf (transmission.get_client_name ());
        } catch (Error e) {
            warning ("Reading client name failed: %s", e.message);
        }

        set_secondary_label (info_text);
        set_icon_for_file_name (file.name);
    }

    private void display_multi_files (IncomingFileRequest[] files) {
        set_primary_label ("%d files".printf (files.length));

        uint64 total_size = 0;

        foreach (var file in files) {
            total_size += file.size;
        }

        string info_text = format_size (total_size);

        try {
            info_text += _(" - From: %s").printf (transmission.get_client_name ());
        } catch (Error e) {
            warning ("Reading client name failed: %s", e.message);
        }

        set_secondary_label (info_text);
        set_icon_from_icon_name ("network-workgroup");
    }

    private void display_progress (uint64 bytes_received, uint64 total_size) {
        set_secondary_label (_("%s of %s").printf (format_size (bytes_received), format_size (total_size)));
        set_progress (bytes_received, total_size);
    }
}
