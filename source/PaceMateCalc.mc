import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Application.Properties;

// Property keys and race-math helpers for the PaceMate data field.
// Canonical units are always meters and seconds; unit conversion only
// happens at display time.
module PaceMateCalc {

    const PROP_DISTANCE_M = "raceDistanceM";
    const PROP_FINISH_SEC = "finishTimeSec";
    const PROP_UNITS = "distanceUnits";
    const PROP_DISTANCE_DISPLAY = "raceDistanceDisplay";
    const PROP_FINISH_MIN = "finishTimeMin";
    const PROP_SHOW_TARGET = "showTargetPace";
    const PROP_SHOW_DELTA = "showDelta";
    const PROP_SHOW_FINISH = "showProjectedFinish";
    const PROP_SHOW_AVERAGE = "showAveragePace";

    enum {
        UNITS_KM = 0,
        UNITS_MILES = 1
    }

    const METERS_PER_KM = 1000.0;
    const METERS_PER_MILE = 1609.344;

    function getRaceDistanceM() as Float {
        var v = Properties.getValue(PROP_DISTANCE_M);
        if (v == null || v <= 0) {
            return 5000.0;
        }
        return v.toFloat();
    }

    function getFinishTimeSec() as Number {
        var v = Properties.getValue(PROP_FINISH_SEC);
        if (v == null || v <= 0) {
            return 1800;
        }
        return v.toNumber();
    }

    function getUnits() as Number {
        var v = Properties.getValue(PROP_UNITS);
        return (v == null) ? UNITS_KM : v.toNumber();
    }

    function getShowTargetPace() as Boolean {
        var v = Properties.getValue(PROP_SHOW_TARGET);
        return (v == null) ? false : v;
    }

    function getShowDelta() as Boolean {
        var v = Properties.getValue(PROP_SHOW_DELTA);
        return (v == null) ? true : v;
    }

    function getShowProjectedFinish() as Boolean {
        var v = Properties.getValue(PROP_SHOW_FINISH);
        return (v == null) ? true : v;
    }

    function getShowAveragePace() as Boolean {
        var v = Properties.getValue(PROP_SHOW_AVERAGE);
        return (v == null) ? true : v;
    }

    function setRaceDistanceM(meters as Float) as Void {
        Properties.setValue(PROP_DISTANCE_M, meters);
        Properties.setValue(PROP_DISTANCE_DISPLAY, meters / unitDistanceMeters());
    }

    function setFinishTimeSec(seconds as Number) as Void {
        Properties.setValue(PROP_FINISH_SEC, seconds);
        Properties.setValue(PROP_FINISH_MIN, seconds / 60);
    }

    function setUnits(units as Number) as Void {
        Properties.setValue(PROP_UNITS, units);
        // Re-derive the display distance in the newly selected unit so
        // the phone-side field stays consistent with the canonical meters.
        Properties.setValue(PROP_DISTANCE_DISPLAY, getRaceDistanceM() / unitDistanceMeters());
    }

    function unitDistanceMeters() as Float {
        return (getUnits() == UNITS_MILES) ? METERS_PER_MILE : METERS_PER_KM;
    }

    function unitLabel() as String {
        return (getUnits() == UNITS_MILES) ? "mi" : "km";
    }

    // Target pace in seconds per display-unit (per km or per mile).
    function targetPaceSecPerUnit() as Float {
        var distanceM = getRaceDistanceM();
        if (distanceM <= 0) {
            return 0.0;
        }
        var unitsCount = distanceM / unitDistanceMeters();
        if (unitsCount <= 0) {
            return 0.0;
        }
        return getFinishTimeSec() / unitsCount;
    }

    // Pace in seconds per display-unit, from a distance/time window (e.g.
    // the last ~100m). Used instead of raw instantaneous speed to smooth
    // out GPS jitter while still updating every second.
    function paceSecPerUnitFromWindow(distanceM as Float, timeSec as Float) as Float {
        if (distanceM <= 0 || timeSec <= 0) {
            return 0.0;
        }
        var unitsCount = distanceM / unitDistanceMeters();
        if (unitsCount <= 0) {
            return 0.0;
        }
        return timeSec / unitsCount;
    }

    // Positive => running slower than target (behind); negative => ahead.
    function paceDeltaSec(currentPaceSec as Float, targetPaceSec as Float) as Float {
        if (currentPaceSec <= 0 || targetPaceSec <= 0) {
            return 0.0;
        }
        return currentPaceSec - targetPaceSec;
    }

    // Projected finish time (seconds) based on elapsed distance/time and
    // current pace, blended with target pace for the remaining distance.
    function projectedFinishSec(elapsedDistanceM as Float or Null, elapsedTimeSec as Float or Null, currentPaceSec as Float) as Number {
        var distanceM = getRaceDistanceM();
        if (elapsedDistanceM == null || elapsedTimeSec == null || elapsedDistanceM <= 0 || distanceM <= 0) {
            return getFinishTimeSec();
        }
        if (elapsedDistanceM >= distanceM) {
            return elapsedTimeSec.toNumber();
        }
        var remainingM = distanceM - elapsedDistanceM;
        var paceSecPerUnit = currentPaceSec;
        if (paceSecPerUnit <= 0) {
            paceSecPerUnit = targetPaceSecPerUnit();
        }
        var remainingUnits = remainingM / unitDistanceMeters();
        var remainingSec = remainingUnits * paceSecPerUnit;
        return (elapsedTimeSec + remainingSec).toNumber();
    }

    // Formats seconds-per-unit pace as M:SS.
    function formatPace(paceSec as Float) as String {
        if (paceSec <= 0 || paceSec.toNumber() > 5999) {
            return "--:--";
        }
        var totalSec = paceSec.toNumber();
        var mins = totalSec / 60;
        var secs = totalSec % 60;
        return mins.format("%d") + ":" + secs.format("%02d");
    }

    // Formats a +/- pace delta as e.g. "+0:07" or "-0:12".
    function formatPaceDelta(deltaSec as Float) as String {
        if (deltaSec == 0.0) {
            return "0:00";
        }
        var sign = (deltaSec > 0) ? "+" : "-";
        var absSec = (deltaSec > 0) ? deltaSec.toNumber() : (-deltaSec).toNumber();
        var mins = absSec / 60;
        var secs = absSec % 60;
        return sign + mins.format("%d") + ":" + secs.format("%02d");
    }

    // Formats seconds as H:MM:SS (or M:SS if under an hour).
    function formatDuration(totalSeconds as Number) as String {
        if (totalSeconds == null || totalSeconds <= 0) {
            return "--:--";
        }
        var hours = totalSeconds / 3600;
        var mins = (totalSeconds % 3600) / 60;
        var secs = totalSeconds % 60;
        if (hours > 0) {
            return hours.format("%d") + ":" + mins.format("%02d") + ":" + secs.format("%02d");
        }
        return mins.format("%d") + ":" + secs.format("%02d");
    }

    // Formats a distance in meters using the configured display unit.
    function formatDistance(meters as Float) as String {
        var units = meters / unitDistanceMeters();
        return units.format("%.2f") + " " + unitLabel();
    }

    // Converts the phone-facing display properties (raceDistanceDisplay
    // in whichever unit distanceUnits currently selects, finishTimeMin in
    // minutes) into the canonical properties the rest of the app uses.
    // Called from AppBase.onSettingsChanged() after a Garmin Connect
    // Mobile / Garmin Express save.
    function applyDisplayProperties() as Void {
        var displayDistance = Properties.getValue(PROP_DISTANCE_DISPLAY);
        if (displayDistance != null && displayDistance > 0) {
            setRaceDistanceM(displayDistance.toFloat() * unitDistanceMeters());
        }

        var displayMinutes = Properties.getValue(PROP_FINISH_MIN);
        if (displayMinutes != null && displayMinutes > 0) {
            setFinishTimeSec(displayMinutes.toNumber() * 60);
        }
    }
}
