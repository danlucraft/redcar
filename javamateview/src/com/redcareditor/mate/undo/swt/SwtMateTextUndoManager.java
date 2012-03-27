package com.redcareditor.mate.undo.swt;

import java.util.Stack;

import org.eclipse.jface.text.source.SourceViewer;
import org.eclipse.swt.custom.ExtendedModifyEvent;
import org.eclipse.swt.custom.ExtendedModifyListener;
import org.eclipse.swt.custom.StyledText;

import com.redcareditor.mate.MateText;
import com.redcareditor.mate.undo.MateTextUndoManager;

/**
 * this class can be attached to {@link MateText} widgets to provide undo/redo.<br>
 * It will plug into the event handling of the text editing widget of
 * {@link MateText} which is currently a {@link StyledText} inside a
 * {@link SourceViewer}.
 */
public class SwtMateTextUndoManager implements ExtendedModifyListener, MateTextUndoManager {
	// TODO: maybe these stacks needs limits, if we want unlimited undo/redo,
	// there you go...
	private Stack<UndoRedoStep> undoStack;
	private Stack<UndoRedoStep> redoStack;
	private StyledText styledText;

	public SwtMateTextUndoManager(MateText matetext) {
		styledText = matetext.getTextWidget();
		undoStack = new Stack<UndoRedoStep>();
		redoStack = new Stack<UndoRedoStep>();
		styledText.addExtendedModifyListener(this);
	}

	/**
	 * this method will get called once the text widget is modified.
	 */
	public void modifyText(ExtendedModifyEvent e) {
		String currentText = styledText.getText();
		String newText = currentText.substring(e.start, e.start + e.length);
		
		if (isTextReplaceEvent(e)) {
			undoStack.push(new ReplaceStep(e.start, e.replacedText));
		}
		if (isTextEntryEvent(newText)) {
			undoStack.push(new EntryStep(e.start, newText));
		}
	}

	/* (non-Javadoc)
	 * @see com.redcareditor.mate.MateTexUndoManager#undo()
	 */
	public void undo() {
		if (!undoStack.isEmpty()) {
			undoStack.pop().undo();
		}
	}

	/* (non-Javadoc)
	 * @see com.redcareditor.mate.MateTexUndoManager#redo()
	 */
	public void redo() {
		if (!redoStack.isEmpty()) {
			redoStack.pop().redo();
		}
	}

	/* (non-Javadoc)
	 * @see com.redcareditor.mate.MateTexUndoManager#isDirty()
	 */
	public boolean isDirty() {
		return !undoStack.empty();
	}

	private boolean isTextEntryEvent(String newText) {
		return newText != null && newText.length() > 0;
	}

	private boolean isTextReplaceEvent(ExtendedModifyEvent e) {
		return e.replacedText != null && e.replacedText.length() > 0;
	}

	private void attachListener() {
		styledText.addExtendedModifyListener(this);
	}

	private void disattachListener() {
		styledText.removeExtendedModifyListener(this);
	}

	/*
	 * ---------------------------------------------------------- these are
	 * private classes, because the outside world doesn't need or understand
	 * them. Plus we can easily access and juggle around the instance variables
	 * from here. ----------------------------------------------------------
	 */
	private abstract class UndoRedoStep {
		public int location;
		public String text;

		public UndoRedoStep(int location, String text) {
			super();
			this.location = location;
			this.text = text;
		}

		@Override
		public String toString() {
			return getClass().getName() + String.format("{%d : %s}", location, text);
		}

		public abstract void undo();

		public abstract void redo();
	}

	/**
	 * When text is replaced or deleted. Deleting is considered replacing it
	 * with ''
	 */
	private class ReplaceStep extends UndoRedoStep {
		public ReplaceStep(int location, String text) {
			super(location, text);
		}

		public void redo() {
			disattachListener();
			undoStack.push(new EntryStep(location, text));
			styledText.replaceTextRange(location, 0, text);
			styledText.setCaretOffset(location + text.length());
			attachListener();
		}

		public void undo() {
			disattachListener();
			redoStack.push(new EntryStep(location, text));
			styledText.replaceTextRange(location, 0, text);
			styledText.setCaretOffset(location + text.length());
			attachListener();
		}
	}

	/**
	 * Represents text that has been entered. Also deleted text, that is undone.
	 */
	private class EntryStep extends UndoRedoStep {
		public EntryStep(int location, String text) {
			super(location, text);
		}

		public void redo() {
			disattachListener();
			undoStack.push(new ReplaceStep(location, text));
			styledText.replaceTextRange(location, text.length(), "");
			styledText.setCaretOffset(location + text.length());
			attachListener();
		}

		public void undo() {
			disattachListener();
			String changedText = styledText.getText().substring(location, location + text.length());
			redoStack.push(new ReplaceStep(location, changedText));
			styledText.replaceTextRange(location, text.length(), "");
			styledText.setCaretOffset(location + text.length());
			attachListener();
		}
	}
}
