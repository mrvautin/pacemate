import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Custom distance picker: whole units + tenths, in the currently
// configured display unit (km or miles). Converted to meters on accept.
class PaceMateCustomDistancePicker extends WatchUi.Picker {
    public function initialize() {
        var unitLabel = PaceMateCalc.unitLabel();
        var title = new WatchUi.Text({
            :text => "Distance (" + unitLabel + ")",
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_BLACK
        });

        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        var tenths = ((distanceUnits - whole) * 10).toNumber();
        if (whole > 200) {
            whole = 200;
        }

        var factories = [
            new NumberFactory(0, 200, 1, {:format => "%d"}),
            new WatchUi.Text({:text => ".", :font => Graphics.FONT_MEDIUM, :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER, :color => Graphics.COLOR_BLACK}),
            new NumberFactory(0, 9, 1, {:format => "%d"})
        ];

        var defaults = [
            (factories[0] as NumberFactory).getIndex(whole),
            0,
            (factories[2] as NumberFactory).getIndex(tenths)
        ];

        Picker.initialize({:title => title, :pattern => factories, :defaults => defaults});
    }
}

class PaceMateCustomDistancePickerDelegate extends WatchUi.PickerDelegate {
    public function initialize() {
        PickerDelegate.initialize();
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    public function onAccept(values as Array) as Boolean {
        var whole = values[0] as Number;
        var tenths = values[2] as Number;
        var distanceUnits = whole + (tenths / 10.0);
        if (distanceUnits <= 0) {
            distanceUnits = 0.1;
        }
        var meters = distanceUnits * PaceMateCalc.unitDistanceMeters();
        PaceMateCalc.setRaceDistanceM(meters);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
