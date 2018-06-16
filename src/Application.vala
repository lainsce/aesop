/*  Author: simargl <https://github.org/simargl>
 *  License: GPL v3
 */

namespace Aesop {
Gtk.ApplicationWindow window;
Gtk.Image image;
Gtk.ScrolledWindow page;

string filename;
int page_count;
int total;
int width;
int height;

int x_start;
int y_start;
int x_current;
int y_current;
int x_end;
int y_end;
bool dragging;
double hadj_value;
double vadj_value;

Gtk.Adjustment hadj;
Gtk.Adjustment vadj;

public class Application: Gtk.Application {
    private const GLib.ActionEntry[] action_entries = {
        { "zoom-plus",            action_zoom_plus            },
        { "zoom-minus",           action_zoom_minus           },
        { "scroll-up",            action_previous_page        },
        { "scroll-down",          action_next_page            },
        { "full-screen-toggle",   action_full_screen_toggle   },
        { "open",                 action_open                 },
        { "quit",                 action_quit                 }
    };

    public Application() {
        Object(application_id: "com.github.lainsce.aesop",
               flags: GLib.ApplicationFlags.HANDLES_OPEN | GLib.ApplicationFlags.NON_UNIQUE);
        add_action_entries(action_entries, this);
    }

    public override void startup() {
        base.startup();
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/lainsce/aesop/stylesheet.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        var settings = AppSettings.get_default ();

        // accelerator
        set_accels_for_action("app.zoom-plus",              {"<Control>Add"});
        set_accels_for_action("app.zoom-minus",             {"<Control>Subtract"});
        set_accels_for_action("app.scroll-up",              {"Up"});
        set_accels_for_action("app.scroll-down",            {"Down"});
        set_accels_for_action("app.full-screen-toggle",     {"F11"});
        set_accels_for_action("app.open",                   {"<Control>O"});
        set_accels_for_action("app.quit",                   {"<Control>Q"});

        // widgets
        image = new Gtk.Image();

        page = new Gtk.ScrolledWindow(null, null);
        page.expand = true;
        page.get_style_context().add_class(Gtk.STYLE_CLASS_VIEW);
        page.add(image);
        page.scroll_event.connect(button_scroll_event);
        var page_context = page.get_style_context ();
        page_context.add_class ("aesop-page");
        hadj = page.get_hadjustment();
        vadj = page.get_vadjustment();

        var stack = new Gtk.Stack ();
        stack.add_named (page, "page");

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (stack);
        grid.show_all ();

        window = new Gtk.ApplicationWindow(this);
        window.window_position = Gtk.WindowPosition.CENTER;
        window.add (grid);
        window.set_icon_name("com.github.lainsce.aesop");
        window.set_default_size(settings.width, settings.height);

        var toolbar = new Gtk.HeaderBar();
        toolbar.title = window.title;
        toolbar.has_subtitle = false;
        toolbar.set_show_close_button (true);
        var toolbar_context = toolbar.get_style_context ();
        toolbar_context.add_class ("aesop-toolbar");
        window.set_titlebar (toolbar);

        var open_button = new Gtk.Button ();
        open_button.has_tooltip = true;
        open_button.set_image (new Gtk.Image.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR));
        open_button.tooltip_text = (_("Open…"));

        open_button.clicked.connect (() => {
            action_open ();
        });

        toolbar.pack_start (open_button);

        window.show_all();

        window.delete_event.connect(() => {
            action_quit();
            return true;
        });

        if (settings.last_file != "") {
            File file = File.new_for_path(settings.last_file);
            if (file.query_exists() == true) {
                filename = settings.last_file;
                page_count = settings.last_page;
                var viewer = new Aesop.Viewer();
                viewer.render_page();
            }
        }
    }

    public override void activate() {
        window.present();
    }

    public override void open(File[] files, string hint) {
        foreach (File f in files) {
            filename = f.get_path();
        }
        page_count = 1;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
        window.present();
    }

    // Mouse EventButton Press
    private bool button_press_event(Gdk.EventButton event) {
        if (event.button == 1 && event.type == Gdk.EventType.2BUTTON_PRESS) {
            action_full_screen_toggle();
        }
        if (event.button == 1 || event.button == 2) {
            var device = Gtk.get_current_event_device();
            if(device != null) {
                event.window.get_device_position(device, out x_start, out y_start, null);
                event.window.set_cursor(new Gdk.Cursor.for_display(Gdk.Display.get_default(),
                                        Gdk.CursorType.FLEUR));
            }
            dragging = true;
            hadj_value = hadj.get_value();
            vadj_value = vadj.get_value();
        }
        return true;
    }

    // motion
    private bool button_motion_event(Gdk.EventMotion event) {
        if (dragging == true) {
            var device = Gtk.get_current_event_device();
            if (device != null) {
                event.window.get_device_position(device, out x_current, out y_current, null);
            }
            int x_diff = x_start - x_current;
            int y_diff = y_start - y_current;
            hadj.set_value(hadj_value + x_diff);
            vadj.set_value(vadj_value + y_diff);
        }
        return false;
    }

    // release
    private bool button_release_event(Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_RELEASE) {
            if (event.button == 1 || event.button == 2) {
                var device = Gtk.get_current_event_device();
                if(device != null) {
                    event.window.get_device_position(device, out x_end, out y_end, null);
                    event.window.set_cursor(null);
                }
                dragging = false;
            }
        }
        return false;
    }

    // Mouse EventButton Scroll
    private bool button_scroll_event (Gdk.EventScroll event) {
        Gdk.ScrollDirection direction;
        event.get_scroll_direction (out direction);
        if (direction == Gdk.ScrollDirection.DOWN) {
            action_next_page();
        } else {
            action_previous_page();
        }
        return false;
    }

    private void action_zoom_plus() {
        var page_zoom = new Aesop.PageZoom();
        page_zoom.zoom_plus();
    }

    private void action_zoom_minus() {
        var page_zoom = new Aesop.PageZoom();
        page_zoom.zoom_minus();
    }

    private void action_previous_page() {
        if (page_count < 2) {
            return;
        }
        page_count = page_count - 1;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
    }

    private void action_next_page() {
        if (page_count > (total -1)) {
            return;
        }
        page_count = page_count + 1;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
    }

    private void action_full_screen_toggle() {
        if ((window.get_window().get_state() & Gdk.WindowState.FULLSCREEN) == 0) {
            window.fullscreen();
        } else {
            window.unfullscreen();
        }
    }

    private void action_open() {
        var dialogs = new Aesop.Dialogs();
        dialogs.show_open();
    }

    private void action_quit() {
        window.get_size(out width, out height);
        var settings = AppSettings.get_default ();
        settings.width = width;
        settings.height = height;
        settings.last_page = page_count;
        settings.last_file = filename;
        quit();
    }

    public static int main (string[] args) {
        Aesop.Application app = new Aesop.Application();
        return app.run(args);
    }

}
}
