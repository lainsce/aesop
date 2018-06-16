namespace Aesop {
    public class Dialogs: Gtk.Dialog {
        public void show_open() {
            var dialog = new Gtk.FileChooserDialog("Open", window,
                                                Gtk.FileChooserAction.OPEN,
                                                "Cancel", Gtk.ResponseType.CANCEL,
                                                "Open",   Gtk.ResponseType.ACCEPT);
            if (filename != null) {
                dialog.set_current_folder(Path.get_dirname(filename));
            }
            dialog.set_select_multiple(false);
            dialog.set_modal(true);
            dialog.show();
            if (dialog.run() == Gtk.ResponseType.ACCEPT) {
                filename = dialog.get_filename();
                page_count = 1;
                var viewer = new Aesop.Viewer();
                viewer.render_page();
            }
            dialog.destroy();
        }
    }
}
