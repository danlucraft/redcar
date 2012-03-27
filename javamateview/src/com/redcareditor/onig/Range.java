package com.redcareditor.onig;

public class Range implements Comparable<Range> {
	public int start;
	public int end;

	public Range(int start, int end) {
		super();
		this.start = start;
		this.end = end;
	}

	@Override
	public String toString() {
		if (start == end) {
			return Integer.toString(start);
		}
		return String.format("%d..%d", start, end);
	}

	public boolean isTouching(Range other) {
		if (start < other.start) {
			return other.start <= end + 1;
		} else {
			return start <= other.end + 1;
		}
	}

	public int compareTo(Range o) {
		int compareStart = start - o.start;
		if (compareStart == 0) {
			return end - o.end;
		} else {
			return compareStart;
		}
	}

	@Override
	public boolean equals(Object obj) {
		if (obj instanceof Range) {
			return 0 == compareTo((Range) obj);
		}
		return false;
	}
}
