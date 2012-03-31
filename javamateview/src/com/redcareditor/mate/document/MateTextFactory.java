package com.redcareditor.mate.document;

public interface MateTextFactory {
	public MateTextLocation getTextLocation(int line, int offset);
	
	public MateTextRange getTextRange();
	
	public MateTextRange getTextRange(MateTextLocation start, MateTextLocation end);
}
