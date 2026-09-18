import Toybox.Lang;
import Toybox.WatchUi;

// Custom distance entry as two rows (Units / Tenths), in the currently
// configured display unit (km or miles) - same Menu2-of-rows pattern as
// PaceMateTimeMenu. Converted to meters on accept.
class PaceMateCustomDistanceMenu extends WatchUi.Menu2 {
    public function initialize() {
        var unitLabel = PaceMateCalc.unitLabel();
        Menu2.initialize({:title => "Distance (" + unitLabel + ")"});

        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        if (whole > 200) {
            whole = 200;
        }
        var tenths = ((distanceUnits - whole) * 10).toNumber();

        addItem(new WatchUi.MenuItem("Units", whole.format("%d"), :whole, {}));
        addItem(new WatchUi.MenuItem("Tenths", tenths.format("%d"), :tenths, {}));
    }

    public function onShow() as Void {
        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        var tenths = ((distanceUnits - whole) * 10).toNumber();

        var wholeItem = getItem(0);
        if (wholeItem != null) {
            wholeItem.setSubLabel(whole.format("%d"));
        }
        var tenthsItem = getItem(1);
        if (tenthsItem != null) {
            tenthsItem.setSubLabel(tenths.format("%d"));
        }
    }
}

class PaceMateCustomDistanceMenuDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(menuItem as WatchUi.MenuItem) as Void {
        var id = menuItem.getId();
        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        if (whole > 200) {
            whole = 200;
        }
        var tenths = ((distanceUnits - whole) * 10).toNumber();

        if (id == :whole) {
            WatchUi.pushView(
                new PaceMateValueMenu(PaceMateCalc.unitLabel(), 0, 200, whole, "%d"),
                new PaceMateValueMenuDelegate(method(:onWholePicked)),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (id == :tenths) {
            WatchUi.pushView(
                new PaceMateValueMenu("Tenths", 0, 9, tenths, "%d"),
                new PaceMateValueMenuDelegate(method(:onTenthsPicked)),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }

    // Public: see PaceMateTimeMenu.onHoursPicked for why (method(:onXPicked)
    // can't resolve a private method at runtime).
    public function onWholePicked(value as Number) as Void {
        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        var tenths = ((distanceUnits - whole) * 10).toNumber();
        setDistanceParts(value, tenths);
    }

    public function onTenthsPicked(value as Number) as Void {
        var distanceUnits = PaceMateCalc.getRaceDistanceM() / PaceMateCalc.unitDistanceMeters();
        var whole = distanceUnits.toNumber();
        if (whole > 200) {
            whole = 200;
        }
        setDistanceParts(whole, value);
    }

    private function setDistanceParts(whole as Number, tenths as Number) as Void {
        var distanceUnits = whole + (tenths / 10.0);
        if (distanceUnits <= 0) {
            distanceUnits = 0.1;
        }
        var meters = distanceUnits * PaceMateCalc.unitDistanceMeters();
        PaceMateCalc.setRaceDistanceM(meters);
    }
}
