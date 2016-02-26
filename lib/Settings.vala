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

/**
 * This class provides access to the configuration of the drop daemon.
 */
public class Drop.Settings : Granite.Services.Settings {
    /**
     * The name of the server that's displayed to the user.
     * Leave this empty to use the real user name.
     */
    public string server_name { get; set; }

    /**
     * Sets wether the server is enabled and should receive transmissions.
     */
    public bool server_enabled { get; set; }

    /**
     * Creates a new Settings interface.
     */
    public Settings () {
        base ("org.pantheon.drop.dropd");
    }

    /**
     * Returns the same value like server_name, but already checks,
     * if it's empty and returns the real user name instead.
     */
    public string get_display_name () {
        if (server_name.strip () == "") {
            return Environment.get_real_name ();
        } else {
            return server_name;
        }
    }
}