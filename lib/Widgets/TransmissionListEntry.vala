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
 * The backbone of the transmission widgets.
 */
public class Drop.Widgets.TransmissionListEntry : Gtk.Box {
    /**
     * The action area that can be used to add widgets to control the transmission.
     */
    public Gtk.Box action_area { protected get; private set; }

    private Gtk.Image icon;

    private Gtk.Grid main_grid;

    private Gtk.Label primary_label;
    private Gtk.Label middle_label;
    private Gtk.Label secondary_label;

    private Gtk.Revealer progress_revealer;
    private Gtk.ProgressBar progress_bar;

    /**
     * Creates a new transmission entry and it's ui.
     */
    public TransmissionListEntry () {
        build_ui ();
    }

    private void build_ui () {
        this.orientation = Gtk.Orientation.HORIZONTAL;
        this.spacing = 12;

        main_grid = new Gtk.Grid ();
        main_grid.column_spacing = 12;
        main_grid.row_spacing = 2;

        icon = new Gtk.Image ();

        primary_label = new Gtk.Label ("");
        primary_label.halign = Gtk.Align.START;
        primary_label.valign = Gtk.Align.END;
        primary_label.ellipsize = Pango.EllipsizeMode.MIDDLE;
        primary_label.use_markup = true;

        secondary_label = new Gtk.Label ("");
        secondary_label.halign = Gtk.Align.START;
        secondary_label.valign = Gtk.Align.START;
        secondary_label.hexpand = true;

        progress_revealer = new Gtk.Revealer ();
        progress_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;

        progress_bar = new Gtk.ProgressBar ();
        progress_bar.valign = Gtk.Align.CENTER;

        progress_revealer.add (progress_bar);

        action_area = new Gtk.Box (Gtk.Orientation.VERTICAL, 4);
        action_area.valign = Gtk.Align.CENTER;

        main_grid.attach (icon, 0, 0, 1, 4);
        main_grid.attach (primary_label, 1, 1, 1, 1);
        main_grid.attach (progress_revealer, 1, 2, 1, 1);
        main_grid.attach (secondary_label, 1, 3, 1, 1);

        this.add (main_grid);
        this.add (action_area);
        this.show_all ();
    }

    /**
     * Sets the entry's icon by icon name.
     *
     * @param icon_name Name of the icon.
     */
    protected void set_icon_from_icon_name (string icon_name) {
        icon.set_from_icon_name (icon_name, Gtk.IconSize.DIALOG);
    }

    /**
     * Sets the entry's icon to fit the extension of a file name.
     *
     * @param file_name Filename of the file.
     */
    protected void set_icon_for_file_name (string file_name) {
        icon.set_from_gicon (ContentType.get_icon (ContentType.guess (file_name, null, null)), Gtk.IconSize.DIALOG);
    }

    /**
     * Sets the text of the primary label.
     *
     * @param text Text to set.
     */
    protected void set_primary_label (string text) {
        primary_label.set_label ("<b>" + text + "</b>");
    }

    /**
     * Sets the text of the secondary label.
     *
     * @param text Text to set.
     */
    protected void set_secondary_label (string text) {
        secondary_label.set_label (text);
    }

    /**
     * Sets the visibility of the progress bar.
     *
     * @param visible Visibility of the progress bar.
     */
    protected void set_progress_visible (bool visible) {
        progress_revealer.set_reveal_child (visible);
    }

    /**
     * Updates the value of the progress bar.
     *
     * @param sent Bytes sent.
     * @param size Total size of the file(s) of this transmission.
     */
    protected void set_progress (uint64 sent, uint64 size) {
        progress_bar.set_fraction ((double)sent / size);
    }
}
