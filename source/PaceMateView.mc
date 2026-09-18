import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Compact race data field: current pace, average pace, target pace, and
// pace delta (color-coded ahead/behind) on top, projected finish time
// below. No cycling/tap dependency, since data fields don't reliably
// receive tap input - everything worth seeing mid-run is on screen
// together.
//
// Average pace, target pace, the delta column, and projected finish
// time can each be hidden via Garmin Connect Mobile/Express
// (showAveragePace, showTargetPace, showDelta, showProjectedFinish) -
// hidden fields free their space for whatever's left, rather than
// leaving a blank gap. Current Pace always shows.
class PaceMateFieldView extends WatchUi.DataField {

    // Distance between rolling-pace checkpoints. Garmin's compute() only
    // fires once per second (fixed by the system, not overridable), so
    // "current pace" is instead calculated from elapsed distance/time
    // since the last checkpoint - recomputed every second as that window
    // rolls forward - rather than raw instantaneous GPS speed, which is
    // noisy. This gives a smoother, more representative pace than
    // currentSpeed while still updating every second.
    private const CHECKPOINT_METERS = 100.0;

    // Largest-to-smallest so the fit search below picks the first (i.e.
    // biggest) font whose rendered width still clears the column.
    private const VALUE_FONTS = [
        Graphics.FONT_NUMBER_MEDIUM,
        Graphics.FONT_NUMBER_MILD,
        Graphics.FONT_LARGE,
        Graphics.FONT_MEDIUM,
        Graphics.FONT_SMALL,
        Graphics.FONT_TINY,
        Graphics.FONT_XTINY
    ] as Array<Graphics.FontType>;

    private var _currentPaceSec as Float = 0.0;
    private var _averagePaceSec as Float = 0.0;
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

            // Average pace over the whole activity so far - same
            // distance/time-window math as current pace, just windowed
            // over everything instead of the last ~100m.
            _averagePaceSec = PaceMateCalc.paceSecPerUnitFromWindow(elapsedDistanceM, elapsedTimeSec);
        }

        _deltaSec = PaceMateCalc.paceDeltaSec(_currentPaceSec, _targetPaceSec);
        _projectedFinishSec = PaceMateCalc.projectedFinishSec(elapsedDistanceM, elapsedTimeSec, _currentPaceSec);
    }

    public function onUpdate(dc as Dc) as Void {
        var bgColor = getBackgroundColor();
        var onWhite = (bgColor != Graphics.COLOR_BLACK);
        var fgColor = onWhite ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;
        // Plain LT_GRAY all but disappears on a white field background;
        // DK_GRAY is the equivalent low-emphasis label color there. Same
        // idea for the ahead/behind colors: full-saturation GREEN reads
        // poorly on white, so the dark variants stand in.
        var labelColor = onWhite ? Graphics.COLOR_DK_GRAY : Graphics.COLOR_LT_GRAY;
        var aheadColor = onWhite ? Graphics.COLOR_DK_GREEN : Graphics.COLOR_GREEN;
        var behindColor = onWhite ? Graphics.COLOR_DK_RED : Graphics.COLOR_RED;

        dc.setColor(fgColor, bgColor);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        var showAverage = PaceMateCalc.getShowAveragePace();
        var showTarget = PaceMateCalc.getShowTargetPace();
        var showDelta = PaceMateCalc.getShowDelta();
        var showFinish = PaceMateCalc.getShowProjectedFinish();

        var topLabels = [] as Array<String>;
        var topValues = [] as Array<String>;
        var topColors = [] as Array<Number>;

        topLabels.add("CUR");
        topValues.add(PaceMateCalc.formatPace(_currentPaceSec));
        topColors.add(fgColor);

        if (showAverage) {
            topLabels.add("AVG");
            topValues.add(PaceMateCalc.formatPace(_averagePaceSec));
            topColors.add(fgColor);
        }

        if (showTarget) {
            topLabels.add("TGT");
            topValues.add(PaceMateCalc.formatPace(_targetPaceSec));
            topColors.add(fgColor);
        }

        if (showDelta) {
            var deltaColor = fgColor;
            if (_deltaSec != 0.0) {
                deltaColor = (_deltaSec > 0) ? behindColor : aheadColor;
            }
            topLabels.add("+/-");
            topValues.add(PaceMateCalc.formatPaceDelta(_deltaSec));
            topColors.add(deltaColor);
        }

        var colCount = topLabels.size();

        // Reserve the bottom band only if Projected Finish is shown;
        // otherwise the top row gets the full height to grow into.
        var topBandBottom = showFinish ? (h * 0.58) : h;
        var topBandTop = h * 0.10;
        var labelH = topBandTop + (topBandBottom - topBandTop) * 0.22;
        var valueH = topBandTop + (topBandBottom - topBandTop) * 0.62;

        var colWidth = w / colCount;
        // Leave a little breathing room between columns so adjacent
        // values never touch even at the widest font that still fits.
        var valueMaxWidth = colWidth * 0.90;
        var valueMaxHeight = (topBandBottom - topBandTop) * 0.44;

        var tinyLabelFont = (colCount <= 2) ? Graphics.FONT_TINY : Graphics.FONT_XTINY;
        var topValueFont = fitFont(dc, topValues, valueMaxWidth, valueMaxHeight);

        for (var i = 0; i < colCount; i += 1) {
            var colCenter = colWidth * (i + 0.5);
            dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(colCenter, labelH, tinyLabelFont, topLabels[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.setColor(topColors[i], Graphics.COLOR_TRANSPARENT);
            dc.drawText(colCenter, valueH, topValueFont, topValues[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (!showFinish) {
            return;
        }

        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(w * 0.15, h * 0.58, w * 0.85, h * 0.58);

        // Bottom: projected finish time, full width (safe near the
        // bottom edge since it's centered and narrower than the row above).
        var finishLabelH = h * 0.68;
        var finishValueH = h * 0.85;
        var finishValue = PaceMateCalc.formatDuration(_projectedFinishSec);
        var finishFont = fitFont(dc, [finishValue], w * 0.85, h * 0.24);

        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, finishLabelH, Graphics.FONT_XTINY, "PROJ. FINISH", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, finishValueH, finishFont, finishValue, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Picks the largest font in VALUE_FONTS under which every string in
    // `values` still fits within (maxWidth, maxHeight), so fewer visible
    // fields (or a wider field/bigger watch) render with bigger text
    // instead of the layout leaving space unused.
    private function fitFont(dc as Dc, values as Array<String>, maxWidth as Float, maxHeight as Float) as Graphics.FontType {
        for (var i = 0; i < VALUE_FONTS.size(); i += 1) {
            var font = VALUE_FONTS[i];
            var fits = true;
            for (var j = 0; j < values.size(); j += 1) {
                var dims = dc.getTextDimensions(values[j], font);
                if (dims[0] > maxWidth || dims[1] > maxHeight) {
                    fits = false;
                    break;
                }
            }
            if (fits) {
                return font;
            }
        }
        return Graphics.FONT_XTINY;
    }
}
