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

/**
 * Describes a single row in the transmission partner list.
 */
public class Drop.Widgets.PartnerListEntry : Gtk.Grid {
    /**
     * The transmission partner structure this row is based on.
     */
    public TransmissionPartner transmission_partner { get; construct; }

    /**
     * The selection state of this row.
     */
    public bool selected { get; private set; default = false; }

    /**
     * The encryption state for transmissions to this transmission partner.
     */
    public bool use_encryption { get; private set; default = true; }

    private Gtk.CheckButton selection_check;
    private Gtk.Label display_name_label;
    private Gtk.Label host_name_label;
    private Gtk.ToggleButton encryption_button;

    private bool encryption_optional = true;

    /**
     * Is called when the selection state has changed.
     *
     * @param selected The new selection state of the row.
     */
    public signal void selection_toggled (bool selected);

    /**
     * Is called when the encryption state has changed.
     *
     * @param use_encryption The new encryption state of the row.
     */
    public signal void use_encryption_toggled (bool use_encryption);

    /**
     * Creates a new transmission partner entry.
     *
     * @param transmssion_partner The transmission partner this row should be based on.
     */
    public PartnerListEntry (TransmissionPartner transmission_partner) {
        Object (transmission_partner: transmission_partner);

        if (transmission_partner.port == 0) {
            use_encryption = false;
            encryption_optional = false;
        } else if (transmission_partner.unencrypted_port == 0) {
            use_encryption = true;
            encryption_optional = false;
        }

        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        this.column_spacing = 6;

        selection_check = new Gtk.CheckButton ();

        display_name_label = new Gtk.Label (transmission_partner.display_name);
        display_name_label.get_style_context ().add_class (Granite.StyleClass.H3_TEXT);
        display_name_label.margin_bottom = 1;
        display_name_label.halign = Gtk.Align.START;
        display_name_label.hexpand = true;

        host_name_label = new Gtk.Label (transmission_partner.hostname);
        host_name_label.halign = Gtk.Align.END;

        encryption_button = new Gtk.ToggleButton ();
        encryption_button.image = new Gtk.Image.from_icon_name (use_encryption ? "security-high-symbolic" : "security-low-symbolic", Gtk.IconSize.BUTTON);
        encryption_button.active = use_encryption;
        encryption_button.sensitive = encryption_optional;

        this.attach (selection_check, 0, 0, 1, 1);
        this.attach (display_name_label, 1, 0, 1, 1);
        this.attach (host_name_label, 2, 0, 1, 1);
        this.attach (encryption_button, 3, 0, 1, 1);
    }

    private void connect_signals () {
        selection_check.toggled.connect (() => {
            selected = selection_check.get_active ();

            selection_toggled (selected);
        });

        encryption_button.toggled.connect (() => {
            use_encryption = encryption_button.get_active ();

            ((Gtk.Image)encryption_button.image).set_from_icon_name (use_encryption ? "security-high-symbolic" : "security-low-symbolic", Gtk.IconSize.BUTTON);

            use_encryption_toggled (use_encryption);
        });
    }
}