import Toybox.Lang;
import Toybox.WatchUi;

// Common race distances plus a custom option that opens a value menu.
class PaceMateDistanceMenu extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize({:title => "Race Distance"});
        addItem(new WatchUi.MenuItem("5K", null, :d5k, {}));
        addItem(new WatchUi.MenuItem("10K", null, :d10k, {}));
        addItem(new WatchUi.MenuItem("Half Marathon", null, :dHalf, {}));
        addItem(new WatchUi.MenuItem("Marathon", null, :dFull, {}));
        addItem(new WatchUi.MenuItem("Custom", null, :dCustom, {}));
    }
}

class PaceMateDistanceMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (id == :d5k) {
            PaceMateCalc.setRaceDistanceM(5000.0);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :d10k) {
            PaceMateCalc.setRaceDistanceM(10000.0);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :dHalf) {
            PaceMateCalc.setRaceDistanceM(21097.5);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :dFull) {
            PaceMateCalc.setRaceDistanceM(42195.0);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :dCustom) {
            WatchUi.pushView(new PaceMateCustomDistanceMenu(), new PaceMateCustomDistanceMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
