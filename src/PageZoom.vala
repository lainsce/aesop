namespace Aesop {
public class PageZoom: GLib.Object {
    double zoom;
    public void zoom_plus() {
        zoom = zoom + 0.25;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
        var settings = AppSettings.get_default ();
        settings.zoom = zoom;
    }

    public void zoom_minus() {
        if (zoom < 0.25) {
            return;
        }
        zoom = zoom - 0.25;
        var viewer = new Aesop.Viewer();
        viewer.render_page();
        var settings = AppSettings.get_default ();
        settings.zoom = zoom;
    }

}
}
