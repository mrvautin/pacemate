import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Compact race data field: current pace, target pace, and pace delta
// (color-coded ahead/behind) on top, projected finish time below. No
// cycling/tap dependency, since data fields don't reliably receive tap
// input - everything worth seeing mid-run is on screen together.
class PaceMateFieldView extends WatchUi.DataField {

    // Distance between rolling-pace checkpoints. Garmin's compute() only
    // fires once per second (fixed by the system, not overridable), so
    // "current pace" is instead calculated from elapsed distance/time
    // since the last checkpoint - recomputed every second as that window
    // rolls forward - rather than raw instantaneous GPS speed, which is
    // noisy. This gives a smoother, more representative pace than
    // currentSpeed while still updating every second.
    private const CHECKPOINT_METERS = 100.0;

    private var _currentPaceSec as Float = 0.0;
    private var _targetPaceSec as Float = 0.0;
    private var _deltaSec as Float = 0.0;
    private var _projectedFinishSec as Number = 0;

    private var _checkpointDistanceM as Float = 0.0;
    private var _checkpointTimeSec as Float = 0.0;

    public function initialize() {
        DataField.initialize();
    }

    public function compute(info as Activity.Info) as Void {
        _targetPaceSec = PaceMateCalc.targetPaceSecPerUnit();

        var elapsedDistanceM = info.elapsedDistance;
        var elapsedTimeSec = (info.timerTime != null) ? info.timerTime / 1000.0 : null;

        if (elapsedDistanceM != null && elapsedTimeSec != null) {
            var distanceSinceCheckpoint = elapsedDistanceM - _checkpointDistanceM;

            if (distanceSinceCheckpoint >= CHECKPOINT_METERS) {
                // Rolled past the next 100m mark: compute pace over that
                // window, then advance the checkpoint to here.
                var timeSinceCheckpoint = elapsedTimeSec - _checkpointTimeSec;
                _currentPaceSec = PaceMateCalc.paceSecPerUnitFromWindow(distanceSinceCheckpoint, timeSinceCheckpoint);
                _checkpointDistanceM = elapsedDistanceM;
                _checkpointTimeSec = elapsedTimeSec;
            } else if (distanceSinceCheckpoint > 0) {
                // Still within the current 100m window: show pace over
                // the partial window so it's never stuck for up to 100m.
                var partialTime = elapsedTimeSec - _checkpointTimeSec;
                _currentPaceSec = PaceMateCalc.paceSecPerUnitFromWindow(distanceSinceCheckpoint, partialTime);
            }
        }

        _deltaSec = PaceMateCalc.paceDeltaSec(_currentPaceSec, _targetPaceSec);
        _projectedFinishSec = PaceMateCalc.projectedFinishSec(elapsedDistanceM, elapsedTimeSec, _currentPaceSec);
    }

    public function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        var col1 = w * 0.25;
        var col2 = w * 0.50;
        var col3 = w * 0.75;

        var tinyLabelFont = Graphics.FONT_XTINY;
        var topValueFont = (w < 200) ? Graphics.FONT_TINY : Graphics.FONT_SMALL;
        var finishFont = Graphics.FONT_NUMBER_MILD;

        var deltaColor = fgColor;
        if (_deltaSec != 0.0) {
            deltaColor = (_deltaSec > 0) ? Graphics.COLOR_RED : Graphics.COLOR_GREEN;
        }

        // Rows are pushed toward the vertical center on purpose: on round
        // screens the usable width near the very top/bottom of the field
        // is much narrower than at the equator, so text at col1/col3
        // clips under the bezel if placed too close to the top edge.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1, h * 0.20, tinyLabelFont, "CUR", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col2, h * 0.20, tinyLabelFont, "TGT", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col3, h * 0.20, tinyLabelFont, "+/-", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col1, h * 0.34, topValueFont, PaceMateCalc.formatPace(_currentPaceSec), Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(col2, h * 0.34, topValueFont, PaceMateCalc.formatPace(_targetPaceSec), Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(deltaColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(col3, h * 0.34, topValueFont, PaceMateCalc.formatPaceDelta(_deltaSec), Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.15, h * 0.58, w * 0.85, h * 0.58);

        // Bottom: projected finish time, full width (safe near the
        // bottom edge since it's centered and narrower than the row above).
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.64, tinyLabelFont, "PROJ. FINISH", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.78, finishFont, PaceMateCalc.formatDuration(_projectedFinishSec), Graphics.TEXT_JUSTIFY_CENTER);
    }
}
