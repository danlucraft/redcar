package com.redcareditor.mate.document.swt;

import org.eclipse.jface.text.Position;
import org.eclipse.jface.text.Document;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.jface.text.BadLocationException;

import com.redcareditor.mate.document.MateDocument;
import com.redcareditor.mate.document.MateTextLocation;
import com.redcareditor.mate.document.MateTextLocationComparator;

public class SwtMateTextLocation extends Position implements MateTextLocation {

	private static final MateTextLocationComparator comperator = new MateTextLocationComparator();
	private Document document;

	public SwtMateTextLocation(int offset, SwtMateDocument document) {
		super(offset);
		this.document = (Document) document.getJFaceDocument();
	}

	public SwtMateTextLocation(int line, int lineOffset, SwtMateDocument document) {
		super(computeOffset(line, lineOffset, (Document) document.getJFaceDocument()));
		this.document = (Document) document.getJFaceDocument();
	}

	public SwtMateTextLocation(MateTextLocation location, SwtMateDocument document) {
		super(computeOffset(location.getLine(), location.getLineOffset(), (Document) document.getJFaceDocument()));
		this.document = (Document) document.getJFaceDocument();
	}

	public void setDocument(MateDocument document) {
		this.document = (Document) ((SwtMateDocument) document).getJFaceDocument();
	}

	public int getLine() {
		try {
			return document.getLineOfOffset(getOffset());
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return -1;
		}
	}

	public int getLineOffset() {
		try {
			return getOffset() - document.getLineOffset(getLine());
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return -1;
		}
	}

	public int compareTo(MateTextLocation other) {
		return this.offset - ((SwtMateTextLocation)other).offset;
	}
	
	//@Override
	//public int getOffset() {
	//	return this.offset < document.getLength() ? this.offset : document.getLength();
	//}
	
	private static int computeOffset(int line, int offset, Document document){
		try {
			line = line < 0 ? 0 : line;
			
			int result = document.getLineOffset(line) + offset;
			
			result = result < 0 ? 0 : result;
			result = result > document.getLength() ? document.getLength() : result; 
			return result;
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return -1;
		}
	}
	
	@Override
	public boolean equals(Object other) {
		if(other instanceof MateTextLocation){
			return compareTo((MateTextLocation) other) == 0;
		}
		return false;
	}
}
