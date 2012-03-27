package com.redcareditor.onig;

import java.io.UnsupportedEncodingException;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.jcodings.Encoding;
import org.jcodings.specific.UTF8Encoding;

import org.joni.Regex;
import org.joni.Region;

public class Match implements Iterable<Range> {
	private Regex regex;
	private Region region;
	private String text;
	
	private boolean charOffsetUpdated;
	private Region charOffsets;

	public Match() {}
	
	public Match(Regex regex, Region region, String text) {
		super();
		this.regex = regex;
		this.region = region;
		this.text = text;
	}

	public int numCaptures() {
		return region.numRegs;
	}

	public Range getCapture(int capture) {
		// checkBounds(capture);
		updateCharOffset();
		return new Range(
				charOffsets.beg[capture],
				charOffsets.end[capture]
			);
	}

	public Range getByteCapture(int capture) {
		// checkBounds(capture);
		updateCharOffset();
		return new Range(
				region.beg[capture],
				region.end[capture]
			);
	}

	private void checkBounds(int capture) {
//		System.out.printf("checkBounds(%d) (out of %d)\n", capture, numCaptures()-1);
		if (capture > numCaptures()-1 || capture < 0) {
			throw new IllegalArgumentException("Capture Index out of bounds!");
		}
	}

	public List<Range> ranges() {
		List<Range> result = new ArrayList<Range>();
		for (Range r : this) {
			result.add(r);
		}
		return result;
	}
	
	
	private static final class Pair implements Comparable {
		int bytePos, charPos;
		public int compareTo(Object o) {
			return bytePos - ((Pair)o).bytePos;
		}
	}
 
	private void updateCharOffset() {
		if (charOffsetUpdated) return;
 
		int numRegs = region == null ? 1 : region.numRegs;
		if (charOffsets == null || charOffsets.numRegs < numRegs) 
			charOffsets = new Region(numRegs);

		Pair[] pairs = new Pair[numRegs * 2];
		for (int i = 0; i < pairs.length; i++) pairs[i] = new Pair();
 
		int numPos = 0;
		// System.out.printf("regions (numRegs:%d):\n", numRegs);
		for (int i = 0; i < numRegs; i++) {
			// System.out.printf(" [%d, %d]\n", region.beg[i], region.end[i]);
			if (region.beg[i] < 0) {
				numPos++; numPos++;
				continue;
			}
			pairs[numPos++].bytePos = region.beg[i];
			pairs[numPos++].bytePos = region.end[i];
		}
 
		// for (Pair pair : pairs) {
		// 	System.out.printf("  * %d\n", pair.bytePos);
		// }
		
		Arrays.sort(pairs);
 
		Encoding enc = UTF8Encoding.INSTANCE;
		byte[] bytes;
		try {
			bytes = text.getBytes("UTF-8");
		} catch (UnsupportedEncodingException e) {
			e.printStackTrace();
			bytes = text.getBytes();
		}
		int p = 0;
		int s = p;
 
		int c = 0;
		for (int i = 0; i < numPos; i++) {
			int q = s + pairs[i].bytePos;
			c += Match.strLength(enc, bytes, p, q);
			// System.out.printf("p:%d s:%d c:%d q:%d bytePos:%d\n", p, s, c, q, pairs[i].bytePos);
			// System.out.printf("'%s' %d %d %d\n", new String(bytes), Match.strLength(enc, bytes, p, q), p, q);
			pairs[i].charPos = c;
			p = q;
		}
 
		Pair key = new Pair();
		for (int i = 0; i < numRegs; i++) {
			if (region.beg[i] < 0) {
				charOffsets.beg[i] = charOffsets.end[i] = -1;
				continue;
			}
			key.bytePos = region.beg[i];
			charOffsets.beg[i] = pairs[Arrays.binarySearch(pairs, key)].charPos;
			key.bytePos = region.end[i];
			charOffsets.end[i] = pairs[Arrays.binarySearch(pairs, key)].charPos;
			// System.out.printf("  * bytes %d, %d  chars %d, %d\n", region.beg[i], region.end[i], charOffsets.beg[i], charOffsets.end[i]);
		}

		charOffsetUpdated = true;
	}

	
	@Override
	public String toString() {
		StringBuilder bui = new StringBuilder();
		bui.append(text);
		bui.append(region);
		return bui.toString();
	}

	public Iterator<Range> iterator() {
		return new Iterator<Range>() {
			int i = 0;

			public boolean hasNext() {
				return i < numCaptures();
			}

			public Range next() {
				Range r = new Range(region.beg[i], region.end[i]);
				i++;
				return r;
			}

			public void remove() {
				throw new UnsupportedOperationException("no removing!");
			}
		};
	}
	
	public static int searchNonAscii(byte[]bytes, int p, int end) {
		while (p < end) {
			if (!Encoding.isAscii(bytes[p])) return p;
			p++;
		}
		return -1;
	}

	public static int length(Encoding enc, byte[]bytes, int p, int end) {
		int n = enc.length(bytes, p, end);
		if (n > 0 && end - p >= n) return n;
		return end - p >= enc.minLength() ? enc.minLength() : end - p;
	}

	public static int strLength(Encoding enc, byte[] bytes, int p, int end) {
		if (enc.isFixedWidth()) {
			return (end - p + enc.minLength() - 1) / enc.minLength();
		} else if (enc.isAsciiCompatible()) {
			int c = 0;
			while (p < end) {
				if (Encoding.isAscii(bytes[p])) {
					int q = searchNonAscii(bytes, p, end);
					if (q == -1) return c + (end - p);
					c += q - p;
					p = q;
				}
				p += length(enc, bytes, p, end);
				c++;
			}
			return c;
		}
		
		int c;
		for (c = 0; end > p; c++) p += length(enc, bytes, p, end);
		return c;
	}
 
	public static int strLength(byte[] bytes) { 
		return strLength(UTF8Encoding.INSTANCE, bytes, 0, bytes.length);
	}
}
