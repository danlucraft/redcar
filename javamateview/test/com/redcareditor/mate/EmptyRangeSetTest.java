package com.redcareditor.mate;

import static org.junit.Assert.*;

import org.junit.*;

public class EmptyRangeSetTest {
	private RangeSet rs;

	@Before
	public void setUp() throws Exception {
		rs = new RangeSet();
	}

	@Test
	public void testShouldReportEmpty() {
		assertTrue(rs.isEmpty());
	}

	@Test
	public void testShouldAddARange() {
		rs.add(1, 3);
		assertEquals(1, rs.length());
		assertEquals(3, rs.rangeSize());
	}
}

