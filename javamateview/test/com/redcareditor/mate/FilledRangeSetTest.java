package com.redcareditor.mate;

import static org.junit.Assert.*;

import org.junit.Before;
import org.junit.Test;

import com.redcareditor.onig.Range;


public class FilledRangeSetTest {
	private RangeSet rs;

	@Before
	public void setUp() throws Exception {
		rs = new RangeSet();
		rs.add(1, 3);
		rs.add(5, 5);
		rs.add(10, 15);
	}

	@Test
	public void testShouldReportLength() {
		assertEquals(3, rs.length());
	}

	@Test
	public void testShouldReportSize() {
		assertEquals(10, rs.rangeSize());
	}

	@Test
	public void testShouldMergeRanges() {
		rs.add(14, 16);
		assertEquals(rs.length(), 3);
		assertEquals(rs.get(0), new Range(1,3));
		assertEquals(rs.get(1), new Range(5,5));
		assertEquals(rs.get(2), new Range(10,16));
	}

	@Test
	public void testShouldMergeRanges2() {
		rs.add(7, 11);
		assertEquals(rs.length(), 3);
		assertEquals(rs.get(0), new Range(1,3));
		assertEquals(rs.get(1), new Range(5,5));
		assertEquals(rs.get(2), new Range(7,15));
	}

	@Test
	public void testShouldMergeTwoRanges() {
		rs.add(4, 11);
		assertEquals(rs.length(), 1);
		assertEquals(rs.get(0), new Range(1,15));
	}

	@Test
	public void testShouldMergeAllRanges() {
		rs.add(1, 20);
		assertEquals(rs.length(), 1);
		assertEquals(rs.get(0), new Range(1,20));
	}

	@Test
	public void testShouldMergeAdjacentRanges() {
		rs.add(16, 18);
		assertEquals(rs.length(), 3);
		assertEquals(rs.get(0), new Range(1,3));
		assertEquals(rs.get(1), new Range(5,5));
		assertEquals(rs.get(2), new Range(10,18));
	}

	@Test
	public void testShouldMergeTwoAdjacentRanges() {
		rs.add(4, 4);
		assertEquals(rs.length(), 2);
		assertEquals(rs.get(0), new Range(1,5));
		assertEquals(rs.get(1), new Range(10,15));
	}
}


