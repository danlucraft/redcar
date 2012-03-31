/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *******************************************************************************/
package com.redcareditor.mate;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.widgets.Display;

import org.eclipse.jface.text.source.ISharedTextColors;

/*
 * @see org.eclipse.jface.text.source.ISharedTextColors
 * @since 2.1
 */
class SharedTextColors implements ISharedTextColors {

	/** The display table. */
	private Map fDisplayTable;

	/** Creates an returns a shared color manager. */
	public SharedTextColors() {
		super();
	}

	/*
	 * @see ISharedTextColors#getColor(RGB)
	 */
	public Color getColor(RGB rgb) {
		if (rgb == null)
			return null;

		if (fDisplayTable == null)
			fDisplayTable= new HashMap(2);

		final Display display= Display.getCurrent();

		Map colorTable= (Map) fDisplayTable.get(display);
		if (colorTable == null) {
			colorTable= new HashMap(10);
			fDisplayTable.put(display, colorTable);
			display.disposeExec(new Runnable() {
				public void run() {
					dispose(display);
				}
			});
		}

		Color color= (Color) colorTable.get(rgb);
		if (color == null) {
			color= new Color(display, rgb);
			colorTable.put(rgb, color);
		}

		return color;
	}

	/*
	 * @see ISharedTextColors#dispose()
	 */
	public void dispose() {
		if (fDisplayTable == null)
			return;

		Iterator iter= fDisplayTable.values().iterator();
		while (iter.hasNext())
			dispose((Map)iter.next());
		fDisplayTable= null;
	}

	/**
	 * Disposes the colors for the given display.
	 *
	 * @param display the display for which to dispose the colors
	 * @since 3.3
	 */
	private void dispose(Display display) {
		if (fDisplayTable != null)
			dispose((Map)fDisplayTable.remove(display));
	}

	/**
	 * Disposes the given color table.
	 *
	 * @param colorTable the color table that maps <code>RGB</code> to <code>Color</code>
	 * @since 3.3
	 */
	private void dispose(Map colorTable) {
		if (colorTable == null)
			return;

		Iterator iter= colorTable.values().iterator();
		while (iter.hasNext())
			((Color) iter.next()).dispose();

		colorTable.clear();
	}

}
