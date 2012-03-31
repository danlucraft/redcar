package com.redcareditor.onig;

import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;

public class NullMatch extends Match {
	private static NullMatch instance;
	private List<Range> emptyList = new LinkedList<Range>();

	public static NullMatch instance() {
		if (instance == null) {
			instance = new NullMatch();
		}
		return instance;
	}

	private NullMatch() {
		super(null, null, null);
	}

	@Override
	public Range getCapture(int capture) {
		return new Range(0,0);
	}
	
	@Override
	public List<Range> ranges() {
		return emptyList;
	}
	
	@Override
	public int numCaptures() {
		return 0;
	}
	
	@Override
	public String toString() {
		return "NullMatch";
	}

	@Override
	public Iterator<Range> iterator() {
		return new Iterator<Range>() {
			public boolean hasNext() {
				return false;
			}

			public Range next() {
				return null;
			}

			public void remove() {
			}
		};
	}
}
