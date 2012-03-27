package com.redcareditor.mate;

import org.eclipse.swt.widgets.Display;

public class ParseThunk implements Runnable {
	int WAIT                     = 500;
	int DELAY_IF_MODIFIED_WITHIN = 400;
	int DELAY_FOR_USER_INPUT     = 10;
	
	public long timeCreated;
	public long lastModificationTime;
	public int parseFrom;
	public boolean closed;
	public int wait = WAIT;
	
	private Parser parser;
	
	public ParseThunk(Parser parser, int parseFrom) {
		this.parser               = parser;
		this.timeCreated          = System.currentTimeMillis();
		this.lastModificationTime = System.currentTimeMillis();
		this.parseFrom            = parseFrom;
		// System.out.printf("New thunk. parseFrom:%d time: %d\n", parseFrom, timeCreated);
		enqueue();
	}
	
	public void enqueue() {
		Display.getCurrent().timerExec(wait, this);
	}
	
	public void stop() {
		closed = true;
	}
	
	public void run() {
		if (closed)
			return;
		// System.out.printf("Run thunk. time: %s\n", System.currentTimeMillis());
		if (lastModificationTime > System.currentTimeMillis() - DELAY_IF_MODIFIED_WITHIN) {
			// System.out.printf("  Postponing thunk.\n", parseFrom);
			Display.getCurrent().timerExec(wait, this);
		}
		else {
			// System.out.printf("  Once, after 0.5 seconds, parse from %d.\n", parseFrom);
			execute();
		}
	}
	
	public void delayAndUpdate(int lineIx) {
		// System.out.printf("Delay thunk time: %s\n", System.currentTimeMillis());
		this.lastModificationTime = System.currentTimeMillis();
		this.parseFrom = Math.min(parseFrom, lineIx);
	}
	
	public void execute() {
		parser.parserScheduler.thunk = null;
		//System.out.printf("Thunk: parseOnwards(%d)\n", parseFrom);
		parseFrom = parser.parserScheduler.parseOnwards(parseFrom);
		if (parseFrom == -1)
			return;
		if (parseFrom >= parser.getLineCount() - 1)
			return;
		if (parseFrom >= parser.parserScheduler.lastVisibleLine + ParserScheduler.LOOK_AHEAD - 5)
			return;
		if (parseFrom <= parser.getLineCount() - 1) {
			wait = DELAY_FOR_USER_INPUT;
			enqueue();
		}
	}
}

