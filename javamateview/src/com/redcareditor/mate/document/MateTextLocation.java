package com.redcareditor.mate.document;

public interface MateTextLocation extends Comparable<MateTextLocation> {
	public int getOffset();
	public int getLine();
	public int getLineOffset();
	public void setDocument(MateDocument document);
}
