package com.redcareditor.mate.document;

import java.util.Comparator;

public class MateTextLocationComparator implements Comparator<MateTextLocation> {

	public int compare(MateTextLocation arg0, MateTextLocation arg1) {
		int lineCompare = arg0.getLine() - arg1.getLine();

		if (lineCompare == 0) {
			return arg0.getLineOffset() - arg1.getLineOffset();
		}

		return lineCompare;
	}

}
