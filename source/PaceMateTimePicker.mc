import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// H:MM:SS picker for the desired race finish time.
class PaceMateTimePicker extends WatchUi.Picker {
    public function initialize() {
        var title = new WatchUi.Text({
            :text => "Finish Time",
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => WatchUi.LAYOUT_VALIGN_BOTTOM,
            :color => Graphics.COLOR_BLACK
        });

        var totalSec = PaceMateCalc.getFinishTimeSec();
        var hours = totalSec / 3600;
        var mins = (totalSec % 3600) / 60;
        var secs = totalSec % 60;

        var digitFont = Graphics.FONT_MEDIUM;

        var factories = [
            new NumberFactory(0, 9, 1, {:format => "%d", :suffix => "h", :font => digitFont}),
            new WatchUi.Text({:text => ":", :font => Graphics.FONT_MEDIUM, :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER, :color => Graphics.COLOR_BLACK}),
            new NumberFactory(0, 59, 1, {:format => "%02d", :suffix => "m", :font => digitFont}),
            new WatchUi.Text({:text => ":", :font => Graphics.FONT_MEDIUM, :locX => WatchUi.LAYOUT_HALIGN_CENTER, :locY => WatchUi.LAYOUT_VALIGN_CENTER, :color => Graphics.COLOR_BLACK}),
            new NumberFactory(0, 59, 1, {:format => "%02d", :suffix => "s", :font => digitFont})
        ];

        var defaults = [
            (factories[0] as NumberFactory).getIndex(hours),
            0,
            (factories[2] as NumberFactory).getIndex(mins),
            0,
            (factories[4] as NumberFactory).getIndex(secs)
        ];

        Picker.initialize({:title => title, :pattern => factories, :defaults => defaults});
    }
}

class PaceMateTimePickerDelegate extends WatchUi.PickerDelegate {
    public function initialize() {
        PickerDelegate.initialize();
    }

    public function onCancel() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    public function onAccept(values as Array) as Boolean {
        var hours = values[0] as Number;
        var mins = values[2] as Number;
        var secs = values[4] as Number;
        var totalSec = (hours * 3600) + (mins * 60) + secs;
        if (totalSec <= 0) {
            totalSec = 1;
        }
        PaceMateCalc.setFinishTimeSec(totalSec);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}
