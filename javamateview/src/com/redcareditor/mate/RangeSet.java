package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.redcareditor.onig.Range;

public class RangeSet implements Iterable<Range> {
	List<Range> ranges = new ArrayList<Range>();

	public void add(int a, int b) {
		int insertAt = 0;
		Range range = new Range(a, b);

		while (insertAt < length() && ranges.get(insertAt).start < range.start) {
			insertAt++;
		}

		merge(insertAt, range);
	}

	public Range get(int i) {
		return ranges.get(i);
	}

	public int length() {
		return size();
	}
	
	public int size() {
		return ranges.size();
	}

	public int rangeSize() {
		int sizec = 0;
		for (int i = 0; i < length(); i++) {
			sizec += ranges.get(i).end - ranges.get(i).start + 1;
		}
		return sizec;
	}

	public String present() {
		return toString();
	}

	public String toString() {
		StringBuilder sb = new StringBuilder("");
		for (int i = 0; i < length(); i++) {
			sb.append(get(i).toString());
			if (i != length() - 1) {
				sb.append(", ");
			}
		}
		return sb.toString();
	}

	public boolean isEmpty() {
		return ranges.isEmpty();
	}

	public Iterator<Range> iterator() {
		return ranges.iterator();
	}

	private void merge(int mergeAt, Range range) {
		ranges.add(mergeAt, range);

		if (mergeAt > 0) {
			Range beforeMerge = ranges.get(mergeAt - 1);
			if (range.isTouching(beforeMerge)) {
				ranges.remove(mergeAt);
				beforeMerge.end = Math.max(beforeMerge.end, range.end);
				mergeAt--;
				range = ranges.get(mergeAt);
			}
		}

		if (mergeAt + 1 < length()) {
			Range afterMerge = ranges.get(mergeAt + 1);
			while (mergeAt < length() - 1 && range.isTouching(afterMerge)) {
				range.start = Math.min(range.start, afterMerge.start);
				range.end = Math.max(range.end, afterMerge.end);
				ranges.remove(mergeAt + 1);
				if (mergeAt + 1 < length())
					afterMerge = ranges.get(mergeAt + 1);
			}
		}
	}

}
