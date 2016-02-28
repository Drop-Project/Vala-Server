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
 * Widget that can be used to cancel an outgoing transmission and view it's current progress.
 */
public class Drop.Widgets.OutgoingTransmissionListEntry : TransmissionListEntry {
    /**
     * The transmission the entry is built on.
     */
    public OutgoingTransmission transmission { get; private set; }

    private Gtk.Button cancel_button;

    /**
     * Creates a new outgoing transmission entry.
     *
     * @param transmission Transmission to build the entry on.
     */
    public OutgoingTransmissionListEntry (OutgoingTransmission transmission) {
        base ();
        this.transmission = transmission;

        build_ui ();
        display_sending_initialisation ();
        read_state ();
        connect_signals ();
    }

    private void build_ui () {
        cancel_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.BUTTON);
        cancel_button.valign = Gtk.Align.CENTER;
        action_area.add (cancel_button);
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

        cancel_button.clicked.connect (() => {
            try {
                transmission.cancel ();
                this.destroy ();
            } catch (Error e) {
                stderr.printf ("Could not cancel transmition: %s", e.message);
            }
        });
    }

    private void display_state (ClientState state) {
        switch (state) {
            case ClientState.LOADING_FILES:
                display_loading_files ();
                break;
            case ClientState.SENDING_INITIALISATION:
                display_sending_initialisation ();
                break;
            case ClientState.SENDING_REQUEST:
                display_sending_request ();
                break;
            case ClientState.AWAITING_CONFIRMATION:
                display_awaiting_confirmation ();
                break;
            case ClientState.REJECTED:
                display_rejected ();
                break;
            case ClientState.SENDING_DATA:
                display_sending_data ();
                break;
            case ClientState.FINISHED:
                display_finished ();
                break;
            case ClientState.CANCELED:
                display_canceled ();
                break;
            case ClientState.FAILURE:
                display_failure ();
                break;
        }
    }

    private void display_loading_files () {
        set_primary_label (_("Loading files…"));
    }

    private void display_sending_initialisation () {
        try {
            var files = transmission.get_file_requests ();

            if (files.length == 0) {
                warning ("File list invalid.");
                this.destroy ();
                return;
            }

            if (files.length == 1) {
                set_primary_label (files[0].name);
                set_icon_for_file_name (files[0].name);
            } else {
                set_primary_label ("%d files".printf (files.length));
                set_icon_from_icon_name ("network-workgroup");
            }

            set_secondary_label ("Sending initialisation…");
        } catch (Error e) {
            warning ("Reading file request failed: %s", e.message);
        }
    }

    private void display_sending_request () {
        set_secondary_label (_("Sending request…"));
    }

    private void display_awaiting_confirmation () {
        set_secondary_label (_("Awaiting confirmation…"));
    }

    private void display_rejected () {
        set_secondary_label (_("Transmission rejected"));
    }

    private void display_sending_data () {
        set_secondary_label (_("Sending files…"));
        set_progress_visible (true);
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

    private void display_progress (uint64 bytes_sent, uint64 total_size) {
        set_secondary_label (_("%s of %s").printf (format_size (bytes_sent), format_size (total_size)));
        set_progress (bytes_sent, total_size);
    }
}
