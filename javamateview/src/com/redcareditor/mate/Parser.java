package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;
import java.util.logging.Handler;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;

import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.ScrollBar;

import org.eclipse.jface.text.BadLocationException;
import org.eclipse.jface.text.Document;
import org.eclipse.jface.text.IRegion;

import com.redcareditor.mate.ParserScheduler;
import com.redcareditor.mate.document.MateDocument;
import com.redcareditor.mate.document.MateTextLocation;
import com.redcareditor.mate.document.swt.SwtMateDocument;
import com.redcareditor.onig.Match;
import com.redcareditor.onig.Rx;

public class Parser {
	public static int linesParsed = 0;
	public Logger logger;

	public Grammar grammar;
	public MateText mateText;
	public Document document;
	public StyledText styledText;
	public MateDocument mateDocument;
	
	public Scope root;
	public ParserScheduler parserScheduler;
	
	public Parser(Grammar g, MateText m) {
		g.initForUse();
		grammar = g;
		mateText = m;
		styledText = m.getTextWidget();
		makeRoot();
		mateDocument = m.getMateDocument();
		document     = (Document) m.getDocument();
		parserScheduler = new ParserScheduler(this);
		logger = Logger.getLogger("JMV.Parser ");
		logger.setUseParentHandlers(false);
		for (Handler h : logger.getHandlers()) {
			logger.removeHandler(h);
		}
		logger.addHandler(MateText.consoleHandler());
		logger.setLevel(Level.INFO);
	}
	
	public void close() {
		parserScheduler.close();
	}
	
	public void setRoot(Scope root) {
		this.root = root;
		root.setMateText(mateText);
	}
	
	public void makeRoot() {
		this.root = new Scope(mateText, this.grammar.scopeName);
		this.root.isOpen = true;
		DoublePattern dp = new DoublePattern();
		dp.name = this.grammar.name;
		dp.patterns = this.grammar.patterns;
		dp.grammar = this.grammar;
		this.root.pattern = dp;
	}
	
	public int getLineAtOffset(int offset) {
		try {
			return document.getLineOfOffset(offset);
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException offset:%d\n", offset);
			e.printStackTrace();
			return -1;
		}
	}
	
	public int getOffsetAtLine(int line) {
		try {
			return document.getLineOffset(line);
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return -1;
		}
	}
	
	public int getLineCount() {
		return document.getNumberOfLines();
	}
	
	public int getCharCount() {
		return document.getLength();
	}
	
	public String getLine(int line) {
		try {
			IRegion region = document.getLineInformation(line);
			return document.get(region.getOffset(), region.getLength());
		} catch (BadLocationException e) {
			System.out.printf("*** Warning BadLocationException");
			e.printStackTrace();
			return "";
		}
	}
	

	public boolean shouldColour() {
		return (parserScheduler.modifyStart == -1);
	}
	
	public void redrawLine(int lineIx) {
		// System.out.printf("redrawLine(%d)\n", lineIx);
		int startOffset = getOffsetAtLine(lineIx);
		int endOffset;
		int lineCount = getLineCount();
		if (lineIx + 1 < lineCount) {
			endOffset = getOffsetAtLine(lineIx + 1) - 1;
		}
		else {
			endOffset = getCharCount();
		}
		styledText.redrawRange(startOffset, endOffset - startOffset, false);
	}
	
	private Scope scopeBeforeStartOfLine(int lineIx) {
		Scope startScope = this.root.scopeAt(lineIx, 0);
		// System.out.printf("scopeBeforeStartOfLine: %s\n", startScope.pattern.name);
		if (startScope.getStart().getLine() == lineIx) { // || startScope.pattern instanceof SinglePattern) {
			startScope = startScope.containingDoubleScope(lineIx);
			// System.out.printf("scopeBeforeStartOfLine: up %s\n", startScope.pattern.name);
		}

		return startScope;
	}

	private Scope scopeAfterEndOfLine(int lineIx, int lineLength) {
		Scope endScope = this.root.scopeAt(lineIx, lineLength - 1);
		if (endScope.getStart().getLine() == lineIx ) {
			endScope = endScope.containingDoubleScope(lineIx);
		}

		return endScope;
	}
	
	public void clearFrom(int offset) {
		root.clearFrom(offset);
	}
	
	public boolean parseLine(int lineIx) {
		Parser.linesParsed++;
		String line = getLine(lineIx) + "\n";
		int length = line.length();
		//if (length > 1)
		//	logger.info(String.format("parseLine(%d) \"%s\"", lineIx, line.substring(0, line.length() - 1)));
		//else
		//	logger.info(String.format("parseLine(%d)", lineIx));
		if (lineIx > parserScheduler.getParsedUpto())
			parserScheduler.setParsedUpto(lineIx);
		//System.out.printf("getParsedUpto: %d\n", getParsedUpto());
		Scope startScope = scopeBeforeStartOfLine(lineIx);
		Scope endScope1  = scopeAfterEndOfLine(lineIx, length);
		//logger.info(String.format("  startScope is: %s", startScope.name));
		//logger.info(String.format("  endScope1: %s", endScope1.name));
		Scanner scanner = new Scanner(startScope, line, lineIx);
		ArrayList<Scope> allScopes = new ArrayList<Scope>();
		allScopes.add(startScope);
		ArrayList<Scope> closedScopes = new ArrayList<Scope>();
		ArrayList<Scope> removedScopes = new ArrayList<Scope>();
		allScopes.add(startScope);
		//logger.info(String.format("start pretty:\n%s", root.pretty(4)));
		for (Marker m : scanner) {
			Scope expectedScope = getExpectedScope(scanner.getCurrentScope(), lineIx, length, scanner.position);
			// if (expectedScope != null)
			// 	logger.info(String.format("expectedScope: %s (%d, %d)", expectedScope.name, expectedScope.getStart().getLine(), 
			// 		           expectedScope.getStart().getLineOffset()));
			// else
			// 	logger.info("no expected scope");
			// logger.info(String.format("  scope: %s %d-%d (line length: %d)", 
			//				m.pattern.name, m.from, m.match.getCapture(0).end, length));
			if (m.isCloseScope) {
				//logger.info("     (closing)");
				closeScope(scanner, expectedScope, lineIx, line, length, m, 
							allScopes, closedScopes, removedScopes);
			}
			else if (m.pattern instanceof DoublePattern) {
				//logger.info("     (opening)");
				openScope(scanner, expectedScope, lineIx, line, length, m, 
						   allScopes, closedScopes, removedScopes);
			}
			else {
				//logger.info("     (single)");
				singleScope(scanner, expectedScope, lineIx, line, length, m, 
							 allScopes, closedScopes, removedScopes);
			}
			//System.out.printf("pretty:\n%s\n", root.pretty(2));
			scanner.position = m.match.getByteCapture(0).end;
		}
		clearLine(lineIx, startScope, allScopes, closedScopes, removedScopes);
		Scope endScope2 = scopeAfterEndOfLine(lineIx, length);
		//logger.info(String.format("  end_scope2: %s\n", endScope2.name));
		//System.out.printf("end pretty: %s\n", this.root.pretty(4));
//		if (colourer != null) {
//			// System.out.printf("before_uncolour_scopes\n");
//			colourer.uncolourScopes(removedScopes);
//			// System.out.printf("before_colour_line_with_scopes\n");
//			colourer.colourLineWithScopes(allScopes);
//			// System.out.printf("after_colour_line_with_scopes\n");
//       ]
//		else {
//			// stdout.printf("no colourer");
//		]
		return (endScope1 != endScope2);
	}

	public Scope getExpectedScope(Scope currentScope, int line, int lineLength, int lineOffset) {
//		System.out.printf("get_expected_scope(%s, %d, %d)\n", currentScope.name, line, lineOffset);
		if (lineOffset == lineLength)
			return null;
		Scope expectedScope = currentScope.firstChildAfter(mateDocument.getTextLocation(line, lineOffset));
//		System.out.printf("first_child_after: %s\n", expectedScope.name);
		assert(expectedScope != currentScope);
		if (expectedScope != null) {
			if (expectedScope.getStart().getLine() != line)
				expectedScope = null;
			while (expectedScope != null && expectedScope.isCapture) {
				expectedScope = expectedScope.parent;
			}
		}
		return expectedScope;
	}

	public void closeScope(Scanner scanner, Scope expectedScope, int lineIx, String line, 
			int length, Marker m, ArrayList<Scope> allScopes, 
			ArrayList<Scope> closedScopes, ArrayList<Scope> removedScopes) {
		String endMatchString = line.substring(m.from, m.match.getCapture(0).end);
		
		boolean is_ended            = !scanner.getCurrentScope().isOpen; //(scanner.getCurrentScope().getEnd() != null);
		boolean equal_ends          = false;
		boolean equal_inner_ends    = false;
		boolean equal_match_strings = false;
		
		if (is_ended) {
			equal_ends          = (scanner.getCurrentScope().getEnd().equals(mateDocument.getTextLocation(lineIx, m.match.getCapture(0).end)));
			equal_inner_ends    = (scanner.getCurrentScope().getInnerEnd().equals(mateDocument.getTextLocation(lineIx, m.from)));
			equal_match_strings = (scanner.getCurrentScope().endMatchString.equals(endMatchString));
		}
		
		if (is_ended && equal_ends && equal_inner_ends && equal_match_strings) {
			// System.out.printf("closing scope matches expected\n");
			// we have already parsed this line and this scope ends here

			// Re-add the captures from the end of the current scope to the 
			// tracking arrays
			for (Scope child : scanner.getCurrentScope().children) {
				if (child.isCapture && 
						child.getStart().getLine() == lineIx) {
					if (!closedScopes.contains(child))
						closedScopes.add(child);
					if (!allScopes.contains(child))
						allScopes.add(child);
				}
			}
		}
		else {
			// System.out.printf("closing scope does not match expected\n");
			// stdout.printf("closing scope at %d\n", m.from);
//			if (colourer != null) {
//				colourer.uncolourScope(scanner.getCurrentScope(), false);
//			]
			setInnerEndPosSafely(scanner.getCurrentScope(), m, lineIx, length, 0);
			setEndPosSafely(scanner.getCurrentScope(), m, lineIx, length, 0);
			scanner.getCurrentScope().isOpen = false;
			scanner.getCurrentScope().endMatchString = endMatchString;
			//stdout.printf("end_match_string: '%s'\n", scanner.current_scope.end_match_string);
			if (expectedScope != null) {
				scanner.getCurrentScope().removeChild(expectedScope);
				removedScopes.add(expectedScope);
				// @removed_scopes << expected_scope
			}
		}
		removeCloseCaptures(scanner.getCurrentScope());
		handleCaptures(lineIx, length, line, scanner.getCurrentScope(), m, allScopes, closedScopes);
		removedScopes.add(scanner.getCurrentScope()); // so it gets uncoloured
		closedScopes.add(scanner.getCurrentScope());
		scanner.setCurrentScope(scanner.getCurrentScope().parent);
		allScopes.add(scanner.getCurrentScope());
	}


	public void openScope(Scanner scanner, Scope expectedScope, int lineIx, 
			String line, int length, Marker m,
			ArrayList<Scope> allScopes, ArrayList<Scope> closedScopes, ArrayList<Scope> removedScopes ) {
		// System.out.printf("[opening with %d patterns], \n", ((DoublePattern) m.pattern).patterns.size());
		Scope s = new Scope(mateText, m.pattern.name);
		s.pattern = m.pattern;
		s.openMatch = m.match;
		setStartPosSafely(s, m, lineIx, length, 0);
		setInnerStartPosSafely(s, m, lineIx, length, 0);
		s.beginMatchString = line.substring(m.from, m.match.getCapture(0).end);
		
		s.isOpen = true;
		s.isCapture = false;
		s.parent = scanner.getCurrentScope();
		Scope newScope = s;
		// is this a bug? captures aren't necessarily to be put into all_scopes yet surely?
		if (expectedScope != null) {
			// check mod ending scopes as the new one will not have a closing marker
			// but the expected one will:
			// stdout.printf("%s == %s and %s == %s and %s == %s and %s == %s and %s == %s",
			// 			  name, other.name, pattern.name, other.pattern.name, start_loc().to_s(),
			// 			  other.start_loc().to_s(), inner_start_loc().to_s(), other.inner_start_loc().to_s(),
			// 			  begin_match_string, other.begin_match_string);
			// if (!s.name.equals(expectedScope.name)) System.out.printf("different names\n");
			// if (!s.pattern.name.equals(expectedScope.pattern.name)) System.out.printf("different patterns\n");
			// if (!s.getStart().equals(expectedScope.getStart())) System.out.printf("different starts\n");
			// if (!s.getInnerStart().equals(expectedScope.getInnerStart())) System.out.printf("different inner starts\n");
			// if (!s.beginMatchString.equals(expectedScope.beginMatchString)) {
			// 	System.out.printf("different beginMatchStrings '%s'/'%s'\n", s.beginMatchString, expectedScope.beginMatchString);
			// }
			if (s.surfaceIdenticalToModuloEnding(expectedScope)) {
				// System.out.printf("surface_identical_mod_ending: keep expected\n");
				// don't need to do anything as we have already found this,
				// but let's keep the old scope since it will have children and what not.
				newScope = expectedScope;
				for (Scope child : expectedScope.children) {
					// if (!child.isCapture) {
						closedScopes.add(child);
						allScopes.add(child);
					// }
				}
				// handleCaptures(lineIx, length, line, s, m, allScopes, closedScopes);
				scanner.setCurrentScope(expectedScope);
			}
			else {
				// System.out.printf("surface_NOT_identical_mod_ending: replace expected\n");
				if (s.overlapsWith(expectedScope)) {
					scanner.getCurrentScope().removeChild(expectedScope);
					// removed_scopes << expected_scope
					removedScopes.add(expectedScope);
				}
				handleCaptures(lineIx, length, line, s, m, allScopes, closedScopes);
				scanner.getCurrentScope().addChild(s);
				scanner.setCurrentScope(s);
			}
		}
		else {
			handleCaptures(lineIx, length, line, s, m, allScopes, closedScopes);
			scanner.getCurrentScope().addChild(s);
			scanner.setCurrentScope(s);
		}
		allScopes.add(newScope);
	}

	private void singleScope(Scanner scanner, Scope expectedScope, int lineIx, 
							String line, int length, Marker m, 
							ArrayList<Scope> allScopes, ArrayList<Scope> closedScopes, 
							ArrayList<Scope> removedScopes) {
		Scope s = new Scope(this.mateText, m.pattern.name);
		s.pattern = m.pattern;
		s.openMatch = m.match;
		setStartPosSafely(s, m, lineIx, length, 0);
		setEndPosSafely(s, m, lineIx, length, 0);
		s.isOpen = false;
		s.isCapture = false;
//		System.out.printf("beginMatchString '%s' %d - %d\n",  new String(line.getBytes(), m.from, m.match.getCapture(0).end - m.from), m.from, m.match.getCapture(0).end);
		// s.beginMatchString = new String(line.getBytes(), m.from, m.match.getCapture(0).end - m.from); 
		s.beginMatchString = line.substring(m.match.getCapture(0).start, m.match.getCapture(0).end);
		s.parent = scanner.getCurrentScope();
		Scope newScope = s;
		if (expectedScope != null) {
			if (s.surfaceIdenticalTo(expectedScope)) {
				newScope = expectedScope;
				for (Scope child : expectedScope.children) {
					closedScopes.add(child);
				}
			}
			else {
				handleCaptures(lineIx, length, line, s, m, allScopes, closedScopes);
				if (s.overlapsWith(expectedScope)) {
					if (expectedScope == scanner.getCurrentScope()) {
						// we expected this scope to close, but it doesn't
					}
					else {
						scanner.getCurrentScope().removeChild(expectedScope);
						// removed_scopes << expectedScope
						removedScopes.add(expectedScope);
					}
				}
				scanner.getCurrentScope().addChild(s);
			}
		}
		else {
			handleCaptures(lineIx, length, line, s, m, allScopes, closedScopes);
			scanner.getCurrentScope().addChild(s);
		}
		allScopes.add(newScope);
		closedScopes.add(newScope);
	}

	private boolean atEndOfNonFinalLine(int lineIx, int length, int to) {
		return to == length && getLineCount() > lineIx+1;
	}

	public void setStartPosSafely(Scope scope, Marker m, int lineIx, int length, int cap) {
		int to = m.match.getCapture(cap).start;
		// if (atEndOfNonFinalLine(lineIx, length, to)) 
		// 	scope.setStartPos(lineIx+1, 0, false);
		// else
			scope.setStartPos(lineIx, Math.min(to, length), false);
	}

	public void setInnerStartPosSafely(Scope scope, Marker m, int lineIx, int length, int cap) {
		int to = m.match.getCapture(cap).start;
		// if (atEndOfNonFinalLine(lineIx, length, to)) 
		// 	scope.setInnerStartPos(lineIx+1, 0, false);
		// else
			scope.setInnerStartPos(lineIx, Math.min(to, length), false);
	}

	public void setInnerEndPosSafely(Scope scope, Marker m, int lineIx, int length, int cap) {
		int from = m.match.getCapture(cap).start;
		// if (atEndOfNonFinalLine(lineIx, length, from)) {
		// 	scope.setInnerEndPos(lineIx, length, true);
		// }
		// else {
			scope.setInnerEndPos(lineIx, Math.min(from, length-1), true);
		// }
	}
	
	public void setEndPosSafely(Scope scope, Marker m, int lineIx, int length, int cap) {
		int to = m.match.getCapture(cap).end;
		// if (atEndOfNonFinalLine(lineIx, length, to)) {
		// 	scope.setEndPos(lineIx, length, true);
		// }
		// else {
			scope.setEndPos(lineIx, Math.min(to, length-1), true);
		// }
	}
	
	// Opens scopes for captures AND creates closing regexp from
	// captures if necessary.
	public void handleCaptures(int lineIx, int length, String line, 
			Scope scope, Marker m, ArrayList<Scope> allScopes, ArrayList<Scope> closedScopes) {
		makeClosingRegex(line, scope, m);
		collectChildCaptures(lineIx, length, scope, m, allScopes, closedScopes);
	}

	public Rx makeClosingRegex(String line, Scope scope, Marker m) {
		if (m.pattern instanceof DoublePattern && !m.isCloseScope) {
			DoublePattern dp = (DoublePattern) m.pattern;
			// System.out.printf("making closing regex: %s\n", dp.endString);
			Rx rx = Rx.createRx("\\\\(\\d+)");
			Match match;
			int pos = 0;
			StringBuilder src = new StringBuilder("");
			boolean found = false;
			while ((match = rx.search(dp.endString, pos, (int) dp.endString.length())) != null) {
				found = true;
				src.append(dp.endString.substring(pos, match.getCapture(0).start));
				String numstr = dp.endString.substring(match.getCapture(1).start, match.getCapture(1).end);
				int num = Integer.parseInt(numstr);
				// System.out.printf("capture found: %d\n", num);
				String capstr = line.substring(m.match.getCapture(num).start, m.match.getCapture(num).end);
				src.append(Rx.escape(capstr));
				pos = match.getCapture(1).end;
			}
			if (found)
				src.append(dp.endString.substring(pos, dp.endString.length()));
			else
				src.append(dp.endString);
			// System.out.printf("close re: '%s'\n", src.toString());
			scope.closingRegex = Rx.createRx(src.toString());
		}
		return null;
	}
	
	public void removeCloseCaptures(Scope scope) {
		int i = 0;
		ArrayList<Scope> children = scope.children;
		while (i < children.size()) {
			Scope childScope = children.get(i);
			if (childScope.isCloseCapture) {
				children.remove(i);
				i--;
			}
			i++;
		}
	}

	public void collectChildCaptures(int lineIx, int length, Scope scope, 
			Marker m, ArrayList<Scope> allScopes, ArrayList<Scope> closedScopes) {
		Scope s;
		Map<Integer, String> captures;
		boolean isCloseCaptures = false;
		if (m.pattern instanceof SinglePattern) {
			captures = ((SinglePattern) m.pattern).captures;
		}
		else {
			if (m.isCloseScope) {
				isCloseCaptures = true;
				captures = ((DoublePattern) m.pattern).endCaptures;
			}
			else {
				captures = ((DoublePattern) m.pattern).beginCaptures;
			}
			if (((DoublePattern) m.pattern).bothCaptures != null) {
				captures = ((DoublePattern) m.pattern).bothCaptures;
			}
		}
		List<Scope> captureScopes = new ArrayList<Scope>();
		// create capture scopes
		if (captures != null) {
			for (Integer cap : captures.keySet()) {
				if (m.match.numCaptures() - 1 >= cap && m.match.getCapture(cap).start != -1) {
					s = new Scope(mateText, captures.get(cap));
					s.pattern = scope.pattern;
					s.setStartPos(lineIx, Math.min(m.match.getCapture(cap).start, length-1), false);
					setInnerEndPosSafely(s, m, lineIx, length, cap);
					setEndPosSafely(s, m, lineIx, length, cap);
					s.isOpen = false;
					s.isCapture = true;
					s.isCloseCapture = isCloseCaptures;
					s.parent = scope;
					captureScopes.add(s);
					allScopes.add(s);
					closedScopes.add(s);
				}
			}
		}
		// Now we arrange the capture scopes into a tree under the matched
		// scope. We do this by processing the captures in order of offset and 
		// length. For each capture, we check to see if it is a child of an already 
		// placed capture, and if so we add it as a child (we know that the latest 
		// such capture is the one to add it to by the ordering). If not we
		// add it as a child of the matched scope.

		List<Scope> placedScopes = new ArrayList<Scope>();
		Scope parentScope;
		while (captureScopes.size() > 0) {
			s = null;
			// find first and longest remaining scope (put it in 's')
			for (Scope cs : captureScopes) {
				if (s == null || 
						cs.getStart().compareTo(s.getStart()) < 0 || 
						(cs.getStart().compareTo(s.getStart()) == 0 && cs.getLength() > s.getLength())) {
					s = cs;
				}
			}
			//System.out.printf("arrange: %s, start: %d, length: %d\n", s.name, s.startOffset(), s.endOffset() - s.startOffset());
			// look for somewhere to put it from placed_scopes
			parentScope = null;
			for (Scope ps : placedScopes) {
				if (s.getStart().compareTo(ps.getStart()) >= 0 && s.getEnd().compareTo(ps.getEnd()) <= 0) {
					parentScope = ps;
				}
			}
			if (parentScope != null) {
				parentScope.addChild(s);
				s.parent = parentScope;
			}
			else {
				scope.addChild(s);
			}
			// logger.info(String.format("    capture %s", s.name));
			placedScopes.add(s);
			captureScopes.remove(s);
		}
	}

	private ArrayList<Scope> deleteAnyOnLineNotIn(Scope cs, int lineIx, ArrayList<Scope> allScopes) {
		int startOffset = getOffsetAtLine(lineIx);
		int endOffset;
		if (lineIx == getLineCount() - 1)
			endOffset = getCharCount();
		else
			endOffset = getOffsetAtLine(lineIx + 1);
		return cs.deleteAnyBetweenNotIn(startOffset, endOffset, allScopes);
	}

	private void clearLine(int lineIx, Scope startScope, ArrayList<Scope> allScopes, 
							ArrayList<Scope> closedScopes, ArrayList<Scope> removedScopes) {
		// If we are reparsing, we might find that some scopes have disappeared,
		// delete them:
		Scope cs = startScope;
		while (cs != null) {
			// stdout.printf("  removing_scopes from: %s\n", cs.name);
			ArrayList<Scope> newRemovedScopes = deleteAnyOnLineNotIn(cs, lineIx, allScopes);
			removedScopes.addAll(newRemovedScopes);
			cs = cs.parent;
		}

		// any that we expected to close on this line that now don't?
		// first build list of scopes that close on this line (including ones
		// that did but haven't been removed yet).
		ArrayList<Scope> scopesThatClosedOnLine = new ArrayList<Scope>();
		Scope ts = startScope;
		while (ts.parent != null) {
			if (ts.getInnerEnd().getLine() == lineIx) {
				scopesThatClosedOnLine.add(ts);
			}
			ts = ts.parent;
		}
		for (Scope s : scopesThatClosedOnLine) {
			if (!closedScopes.contains(s)) {
				if (s.isCapture) {
					s.parent.removeChild(s);
					removedScopes.add(s);
				}
				else {
					int line = getLineCount() - 1;
					int lineOffset = getCharCount() - getOffsetAtLine(line);
					s.removeEnd();
					s.isOpen = true;
				}
			}
		}
	}
}
