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
    public Gee.ArrayList<File> files { private get; construct; }

    private Drop.Session drop_session;

    private Gtk.Grid main_grid;

    private Gtk.Label header_label;
    private Drop.Widgets.PartnerList partner_list;

    public MainWindow (Gee.ArrayList<File> files) {
        Object (files: files);

        drop_session = new Drop.Session ();

        build_ui ();
    }

    private void build_ui () {
        this.deletable = false;

        main_grid = new Gtk.Grid ();
        main_grid.margin = 12;
        main_grid.margin_top = 0;
        main_grid.row_spacing = 12;
        main_grid.column_spacing = 12;

        header_label = new Gtk.Label (ngettext ("Send %i file…", "Send %i files…", files.size).printf (files.size));
        header_label.get_style_context ().add_class (Granite.StyleClass.H2_TEXT);
        header_label.halign = Gtk.Align.START;

        partner_list = new Drop.Widgets.PartnerList (drop_session, true);
        partner_list.expand = true;

        main_grid.attach (header_label, 0, 0, 1, 1);
        main_grid.attach (partner_list, 0, 1, 1, 1);

        this.get_content_area ().add (main_grid);
    }
}