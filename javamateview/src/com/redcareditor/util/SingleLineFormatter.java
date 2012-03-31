
package com.redcareditor.util;

import java.util.logging.LogRecord;
import java.util.logging.SimpleFormatter;

public class SingleLineFormatter extends SimpleFormatter {
	public String format(LogRecord record) {
		return new java.util.Date().toGMTString() + " " + record.getLoggerName() + " " + record.getLevel() + " " + record.getMessage() + "\r\n";
	}
}
