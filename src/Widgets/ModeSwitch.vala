
public class ModeSwitch : Gtk.Grid {
    public bool active { get; set; }
    public string primary_icon_name { get; construct set; }
    public string primary_icon_tooltip_text { get; set; }
    public string secondary_icon_name  { get; construct set; }
    public string secondary_icon_tooltip_text { get; set; }

    public ModeSwitch (string primary_icon_name, string secondary_icon_name) {
        Object (
            primary_icon_name: primary_icon_name,
            secondary_icon_name: secondary_icon_name
        );
    }

    construct {
        var primary_icon = new Gtk.Image ();
        primary_icon.pixel_size = 16;

        var primary_icon_box = new Gtk.EventBox ();
        primary_icon_box.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        primary_icon_box.add (primary_icon);

        var mode_switch = new Gtk.Switch ();
        mode_switch.valign = Gtk.Align.CENTER;
        mode_switch.get_style_context ().add_class ("mode-switch");

        var secondary_icon = new Gtk.Image ();
        secondary_icon.pixel_size = 16;

        var secondary_icon_box = new Gtk.EventBox ();
        secondary_icon_box.add_events (Gdk.EventMask.BUTTON_RELEASE_MASK);
        secondary_icon_box.add (secondary_icon);

        column_spacing = 6;
        add (primary_icon_box);
        add (mode_switch);
        add (secondary_icon_box);

        bind_property ("primary-icon-name", primary_icon, "icon-name", GLib.BindingFlags.SYNC_CREATE);
        bind_property ("primary-icon-tooltip-text", primary_icon, "tooltip-text");
        bind_property ("secondary-icon-name", secondary_icon, "icon-name", GLib.BindingFlags.SYNC_CREATE);
        bind_property ("secondary-icon-tooltip-text", secondary_icon, "tooltip-text");

        this.notify["active"].connect (() => {
            if (Gtk.StateFlags.DIR_RTL in get_state_flags ()) {
                mode_switch.active = !active;
            } else {
                mode_switch.active = active;
            }
        });

        mode_switch.notify["active"].connect (() => {
            if (Gtk.StateFlags.DIR_RTL in get_state_flags ()) {
                active = !mode_switch.active;
            } else {
                active = mode_switch.active;
            }
        });

        primary_icon_box.button_release_event.connect (() => {
            active = false;
            return Gdk.EVENT_STOP;
        });

        secondary_icon_box.button_release_event.connect (() => {
            active = true;
            return Gdk.EVENT_STOP;
        });
    }
}