package com.redcareditor.mate.undo;

public interface MateTextUndoManager {

	public abstract void undo();

	public abstract void redo();

	public abstract boolean isDirty();

}