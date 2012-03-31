package com.redcareditor.mate.colouring.swt;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.events.PaintEvent;
import org.eclipse.swt.events.PaintListener;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Display;

import com.redcareditor.mate.MateText;

public class MarginPaintListener implements PaintListener {
	static Color marginColor = Display.getCurrent().getSystemColor(SWT.COLOR_WIDGET_NORMAL_SHADOW);
	
	private MateText mateText;
	private StyledText control;


	public MarginPaintListener(MateText mateText) {
		this.mateText = mateText;
		this.control  = mateText.getControl();
	}

	public void paintControl(PaintEvent e) {
		int marginColumn = mateText.getMarginColumn();
		if (marginColumn == -1) return;
		drawMargin(e.gc, marginColumn);
	}

	private void drawMargin(GC gc, int marginColumn) {
		int width = gc.getFontMetrics().getAverageCharWidth() * marginColumn + control.getLeftMargin();
		Rectangle controlBounds = control.getBounds();
		if (gc.getAdvanced()) {
			drawMarginOverlay(gc, width, controlBounds);
		} else {
			drawMarginLine(gc, width, controlBounds);
		}
	}

	private void drawMarginLine(GC gc, int width, Rectangle controlBounds) {
		Color fgColor = gc.getForeground();
		gc.setForeground(getMarginColor());
		gc.drawLine(width, 0, width, controlBounds.height);
		gc.setForeground(fgColor);
	}

	private void drawMarginOverlay(GC gc, int width, Rectangle controlBounds) {
		Color bgColor = gc.getBackground();
		int alpha = gc.getAlpha();
		gc.setBackground(getMarginColor());
		gc.setAlpha(64); // Draw transparently over widget. We cannot draw under the text (!)
		gc.fillRectangle(width, 0, controlBounds.width, controlBounds.height);
		gc.setAlpha(alpha);
		gc.setForeground(bgColor);
	}

	static private Color getMarginColor() {
		return marginColor;
	}
}
