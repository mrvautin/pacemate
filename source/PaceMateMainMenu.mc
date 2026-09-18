import Toybox.Lang;
import Toybox.WatchUi;

class PaceMateMainMenu extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize({:title => "PaceMate Settings"});
        addItem(new WatchUi.MenuItem("Race Distance", PaceMateCalc.formatDistance(PaceMateCalc.getRaceDistanceM()), :distance, {}));
        addItem(new WatchUi.MenuItem("Finish Time", PaceMateCalc.formatDuration(PaceMateCalc.getFinishTimeSec()), :finishTime, {}));
        addItem(new WatchUi.MenuItem("Units", unitsLabel(), :units, {}));
    }

    private function unitsLabel() as String {
        return (PaceMateCalc.getUnits() == PaceMateCalc.UNITS_MILES) ? "Miles" : "Kilometers";
    }

    // Sub-labels are set once at construction; refresh them whenever this
    // menu becomes visible again (e.g. returning from the distance
    // submenu, finish time picker, or units menu) so they don't show
    // stale values.
    public function onShow() as Void {
        var distanceItem = getItem(0);
        if (distanceItem != null) {
            distanceItem.setSubLabel(PaceMateCalc.formatDistance(PaceMateCalc.getRaceDistanceM()));
        }
        var finishItem = getItem(1);
        if (finishItem != null) {
            finishItem.setSubLabel(PaceMateCalc.formatDuration(PaceMateCalc.getFinishTimeSec()));
        }
        var unitsItem = getItem(2);
        if (unitsItem != null) {
            unitsItem.setSubLabel(unitsLabel());
        }
    }
}

class PaceMateMainMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        if (id == :distance) {
            WatchUi.pushView(new PaceMateDistanceMenu(), new PaceMateDistanceMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :finishTime) {
            WatchUi.pushView(new PaceMateTimeMenu(), new PaceMateTimeMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (id == :units) {
            WatchUi.pushView(new PaceMateUnitsMenu(), new PaceMateUnitsMenuDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}
