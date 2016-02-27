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
 * Automatic list that manages incoming transmissions of a Drop session.
 */
public class Drop.Widgets.IncomingTransmissionList : Gtk.Box {
    /**
     * The session the widget uses to communicate with drop-daemon.
     */
    public Session session { get; construct; }

    /**
     * Amount of transmissions listed on the widget.
     */
    public int transmission_count { public get; private set; default = 0; }

    /**
     * Is called when a new transmission appears on the list.
     *
     * @param transmission The transmission that has been added.
     */
    public signal void transmission_added (IncomingTransmission transmission);

    /**
     * Is called when a transmission is removed from the list.
     *
     * @param transmission The transmission that has been removed.
     */
    public signal void transmission_removed (IncomingTransmission transmission);

    construct {
        orientation = Gtk.Orientation.VERTICAL;
    }

    /**
     * Creates a new list of incoming transmissions based on a drop session.
     *
     * @param session Session to build the widget on.
     */
    public IncomingTransmissionList (Session session) {
        Object (session: session);

        load_transmission_list ();
        connect_signals ();
    }

    private void load_transmission_list () {
        try {
            var transmissions = session.get_incoming_transmissions ();

            foreach (var transmission in transmissions) {
                add_transmission (transmission);
            }
        } catch (Error e) {
            warning ("Loading list of incoming transmissions failed: %s", e.message);
        }
    }

    private void connect_signals () {
        session.new_incoming_transmission.connect (add_transmission);
    }

    private void add_transmission (IncomingTransmission transmission) {
        Gtk.Separator? separator = null;

        var entry = new IncomingTransmissionListEntry (transmission);
        entry.margin = 6;

        entry.destroy.connect (() => {
            transmission_removed (transmission);

            if (separator != null) {
                this.remove (separator);
            }

            transmission_count--;
        });

        if (transmission_count > 0) {
            this.add (separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        }

        this.add (entry);

        transmission_count++;
        transmission_added (transmission);
    }
}