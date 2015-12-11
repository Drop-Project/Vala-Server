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

public class DropDialog.MainWindow : Gtk.Dialog {
    public Gee.ArrayList<string> filenames { private get; construct; }
    public bool show_myself { private get; construct; }

    private Drop.Session drop_session;

    private Gtk.Grid main_grid;

    private Gtk.Label header_label;
    private Drop.Widgets.PartnerList partner_list;

    private Gtk.Button close_button;
    private Gtk.Button send_button;

    public MainWindow (Gee.ArrayList<string> filenames, bool show_myself) {
        Object (filenames: filenames, show_myself: show_myself);

        drop_session = new Drop.Session ();

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        this.set_default_size (750, 450);
        this.deletable = false;

        main_grid = new Gtk.Grid ();
        main_grid.margin_start = 12;
        main_grid.margin_end = 12;
        main_grid.margin_bottom = 12;
        main_grid.row_spacing = 18;

        header_label = new Gtk.Label (ngettext ("Send %i file to…", "Send %i files to…", filenames.size).printf (filenames.size));
        header_label.get_style_context ().add_class (Granite.StyleClass.H2_TEXT);
        header_label.halign = Gtk.Align.START;

        partner_list = new Drop.Widgets.PartnerList (drop_session, show_myself);
        partner_list.expand = true;

        main_grid.attach (header_label, 0, 0, 1, 1);
        main_grid.attach (partner_list, 0, 1, 1, 1);

        close_button = (Gtk.Button) this.add_button (_("Close"), Gtk.ResponseType.CLOSE);

        send_button = (Gtk.Button) this.add_button (_("Send"), Gtk.ResponseType.ACCEPT);
        send_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        send_button.sensitive = false;

        this.get_content_area ().add (main_grid);
        this.get_action_area ().margin = 6;
    }

    private void connect_signals () {
        partner_list.entries_changed.connect (() => {
            bool partners_selected = false;

            foreach (Drop.Widgets.PartnerListEntry entry in partner_list.get_entry_rows ().values) {
                if (entry.selected) {
                    partners_selected = true;

                    break;
                }
            }

            send_button.set_sensitive (partners_selected);
        });

        this.response.connect ((response_id) => {
            if (response_id == Gtk.ResponseType.ACCEPT) {
                if (!start_transmissions ()) {
                    return;
                }
            }

            this.destroy ();
        });
    }

    private bool start_transmissions () {
        try {
            foreach (Drop.Widgets.PartnerListEntry entry in partner_list.get_entry_rows ().values) {
                if (entry.selected) {
                    drop_session.start_transmission (entry.transmission_partner.hostname,
                                                     entry.use_encryption ? entry.transmission_partner.port : entry.transmission_partner.unencrypted_port,
                                                     filenames.to_array (),
                                                     entry.use_encryption);

                    break;
                }
            }
        } catch (Error e) {
            warning ("Starting transmissions failed: %s", e.message);

            return false;
        }

        return true;
    }
}