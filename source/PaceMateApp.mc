import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class PaceMateFieldApp extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    public function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new PaceMateFieldView()];
    }

    // Reachable on-device from the activity's menu (hold MENU during/at the
    // start of an activity -> Settings -> PaceMate), per Data Field on-device
    // settings support (Connect IQ API 3.2.0+).
    public function getSettingsView() as [Views] or [Views, InputDelegates] or Null {
        return [new PaceMateSettingsView(), new PaceMateSettingsDelegate()];
    }

    // Called when settings change via Garmin Connect Mobile/Express (and
    // also after the on-device settings menu, though that writes the
    // canonical properties directly). Converts the phone-facing display
    // properties (raceDistanceDisplay in km/mi, finishTimeMin in minutes)
    // into the canonical properties (raceDistanceM, finishTimeSec) the
    // rest of the app actually uses.
    public function onSettingsChanged() as Void {
        PaceMateCalc.applyDisplayProperties();
        WatchUi.requestUpdate();
    }
}
