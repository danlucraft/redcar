package com.redcareditor.mate.document.swt;

import org.eclipse.jface.text.BadLocationException;
import org.eclipse.jface.text.BadPositionCategoryException;
import org.eclipse.jface.text.DefaultPositionUpdater;
import org.eclipse.jface.text.Document;
import org.eclipse.jface.text.IDocument;
import org.eclipse.jface.text.DocumentEvent;
import org.eclipse.jface.text.IDocumentListener;
import org.eclipse.jface.text.IPositionUpdater;
import org.eclipse.jface.text.Position;
import org.eclipse.swt.custom.StyledText;

import com.redcareditor.mate.MateText;
import com.redcareditor.mate.document.MateDocument;
import com.redcareditor.mate.document.MateTextFactory;
import com.redcareditor.mate.document.MateTextLocation;
import com.redcareditor.mate.document.MateTextRange;

public class SwtMateDocument implements MateDocument, MateTextFactory {
	public MateText mateText;
	private IPositionUpdater positionUpdater;
	public Document document;

	public SwtMateDocument(MateText mateText) {
		this.mateText = mateText;
		this.document = (Document) mateText.getDocument();
		for (IPositionUpdater u : document.getPositionUpdaters()) {
			document.removePositionUpdater(u);
		}
		document.addPositionCategory("scopes");
		document.addPositionUpdater(new SwtScopePositionUpdater("scopes", SwtScopePositionUpdater.LEFT_GRAVITY));
		document.addPositionCategory("lefts");
		document.addPositionUpdater(new SwtScopePositionUpdater("lefts", SwtScopePositionUpdater.LEFT_GRAVITY));
		document.addPositionCategory("rights");
		document.addPositionUpdater(new SwtScopePositionUpdater("rights", SwtScopePositionUpdater.RIGHT_GRAVITY));
	}

	public void set(String text) {
		this.mateText.getDocument().set(text);
		//reparseAll();
	}
	
	public IDocument getJFaceDocument() {
		return this.mateText.getDocument();
	}
	
	public String get() {
		return this.mateText.getDocument().get();
	}
	
	public int length() {
		return this.mateText.getDocument().getLength();
	}
	
	public int getNumberOfLines() {
		return this.mateText.getDocument().getNumberOfLines();
	}

	public void reparseAll() {
		SwtMateTextLocation startLocation = new SwtMateTextLocation(0, this);
		SwtMateTextLocation endLocation = new SwtMateTextLocation(0 + document.getLength(), this);
		if (this.mateText.parser.parserScheduler.enabled) {
			this.mateText.parser.parserScheduler.changes.add(startLocation.getLine(), endLocation.getLine());
			this.mateText.parser.parserScheduler.processChanges();
		}
	}

	public void replace(int start, int length, String text) {
		try {
			this.mateText.getDocument().replace(start, length, text);
			SwtMateTextLocation startLocation = new SwtMateTextLocation(start, this);
			SwtMateTextLocation endLocation = new SwtMateTextLocation(start + length, this);
			this.mateText.parser.parserScheduler.changes.add(startLocation.getLine(), endLocation.getLine());
			this.mateText.parser.parserScheduler.processChanges();
		} catch (BadLocationException e) {
			// TODO: SwtMateDocument should throw it's own Exception here
		}
	}

	public boolean addTextLocation(MateTextLocation location) {
		return addTextLocation("default", location);
	}

	public boolean addTextLocation(String category, MateTextLocation location) {
		try {
			mateText.getDocument().addPosition(category, (SwtMateTextLocation) location);
			return true;
		} catch (BadLocationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (BadPositionCategoryException e) {
			e.printStackTrace();
		}

		return false;
	}
	
	public boolean removeTextLocation(String category, MateTextLocation location) {
		try {
			mateText.getDocument().removePosition(category, (SwtMateTextLocation) location);
			return true;
		} catch (BadPositionCategoryException e) {
			e.printStackTrace();
		}
		return false;
	}

	public int getLineCount() {
		return document.getNumberOfLines();
	}

	public int getLineLength(int line) {
		try {
			int startOffset = document.getLineOffset(line);
			int endOffset;
  
			if (line + 1 < getLineCount()) {
				endOffset = document.getLineOffset(line + 1);
			} else {
				endOffset = document.getLength();
			}
  
			return endOffset - startOffset;
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return -1;
		}
	}

	public MateTextLocation getTextLocation(int line, int offset) {
		return new SwtMateTextLocation(line, offset, this);
	}

	public MateTextRange getTextRange(MateTextLocation start, MateTextLocation end) {
		return new SwtMateTextRange(start, end, this);
	}

	public MateTextRange getTextRange() {
		return new SwtMateTextRange(this);
	}
}
