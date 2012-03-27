
package com.redcareditor.mate;

import java.util.List;
import java.util.ArrayList;

import com.redcareditor.mate.document.MateDocument;
import com.redcareditor.mate.document.MateTextLocation;
import com.redcareditor.mate.document.swt.SwtMateTextLocation;
import com.redcareditor.mate.document.MateTextRange;
import com.redcareditor.onig.Match;
import com.redcareditor.onig.Rx;
import com.redcareditor.theme.ThemeSetting;

public class Scope implements Comparable<Scope>{
	private MateText mateText;
	
	private MateDocument document;
	
	private MateTextRange range;
	private MateTextRange innerRange;
	
	public String name;
	public Pattern pattern;
	
	public boolean isOpen;
	public boolean isCapture;
	public boolean isCloseCapture;
	
	public Match openMatch;
	public Match closeMatch;
	
	public Rx closingRegex;
	public String beginMatchString;
	public String endMatchString;
	
	public Scope parent;
	public ArrayList<Scope> children;
	
	public String bgColour;
	public String fgColour;
	
	StringBuilder prettyString;
	int indent;
	
	public ThemeSetting themeSetting;
	
	public Scope(MateText mt, String name) {
		this.mateText = mt;
		this.name = name;
		this.children = new ArrayList<Scope>();
		this.document = mt.getMateDocument();
		
		this.range = document.getTextRange();
		this.innerRange = document.getTextRange();
	}
	
	public void setMateText(MateText mateText) {
		this.mateText = mateText;
		this.document = mateText.getMateDocument();
		this.range.setDocument(this.document);
		if (this.innerRange != null) {
			this.innerRange.setDocument(this.document);
		}
		
		for (Scope child : children)
			child.setMateText(mateText);
	}
	
	static public Scope findContainingScopeOld(ArrayList<Scope> scopes, MateTextLocation location) {
		for (Scope child : scopes) {
			if (child.contains(location)) {
				return child;
			}
		}
		return null;
	}
	
	static int indexOfEarliestAfter(ArrayList<Scope> scopes, int offset) {
		if (offset == 0) {
			if (scopes.size() > 0)
				return 0;
			else
				return -1;
		}
		int ix = indexOfLatestBefore(scopes, offset - 1);
		int c = ix + 1;
		if (c == scopes.size())
			return -1;
		return c;
	}
	
	static int indexOfLatestBefore(ArrayList<Scope> scopes, int offset) {
		int high = scopes.size(), low = -1, probe, probeStart;
		if (high == 0)
			return -1;
		int bestProbe = 0;
		int bestStart = ((SwtMateTextLocation) scopes.get(0).getStart()).offset;
		if (bestStart > offset)
			return -1;
		Scope scope;
		while (high - low > 1) {
			probe = (low + high) >>> 1;
			scope = scopes.get(probe);
			probeStart = ((SwtMateTextLocation) scope.getStart()).offset;
			//System.out.printf("low: %d high: %d diff: %d probe: %d value: %d\n", low, high, high - low, probe, probeStart);
			if (probeStart <= offset) {
				low = probe;
				bestStart = probeStart;
				bestProbe = probe;
			}
			else {
				high = probe;
			}
		}
		if (bestStart <= offset)
			return bestProbe;
		else
			return -1;
	}
	
	static public Scope findContainingScopeNew(ArrayList<Scope> scopes, int offset) {
		//System.out.printf("findContainingScopeNew(offset: %d)\n", offset);
		int ix = indexOfLatestBefore(scopes, offset);
		if (ix == -1)
			return null;
		Scope scope = scopes.get(ix);
		int scopeStart = ((SwtMateTextLocation) scope.getStart()).offset;
		if (scopeStart <= offset) {
			int scopeEnd = ((SwtMateTextLocation) scope.getEnd()).offset;
			if (scopeEnd > offset) {
				return scope;
			}
		}
		return null;
	}

	public Scope scopeAt(int line, int lineOffset) {
		MateTextLocation location = document.getTextLocation(line, lineOffset);
		Scope r = null;		
		if (getStart().compareTo(location) <= 0 || parent == null) {
			if (isOpen || getEnd().compareTo(location) >= 0) {
				Scope containingChildNew = Scope.findContainingScopeNew(children, ((SwtMateTextLocation) location).offset);
				//Scope containingChildOld = Scope.findContainingScopeOld(children, location);
				//if (containingChildNew != containingChildOld) {
				//	System.out.printf("scopeAt(%d, %d)\n", line, lineOffset);
				//	System.out.printf("containingChild differs %s -> %s\n", 
				//		(containingChildOld == null ? "none" : containingChildOld.name),
				//		(containingChildNew == null ? "none" : containingChildNew.name)
				//	);
				//	System.out.printf(pretty(2));
				//}
				if (containingChildNew != null)
					r = containingChildNew.scopeAt(line, lineOffset);
				else
					r = this;
			}
		}
		return r;
	}
	
	public void clearFrom(int offset) {
		//System.out.printf("clearFrom(%d) children: %d\n", offset, children.size());
		int ix = indexOfLatestBefore(children, offset);
		//System.out.printf("  ix: %d\n", ix);
		if (ix == -1)
			return;
		Scope scope = children.get(ix);
		int scopeStart = scope.getStart().getOffset();
		//System.out.printf("  scopeStart: %d\n", scopeStart);
		if (scopeStart < offset) {
			ix = ix + 1;
			int scopeEnd = scope.getEnd().getOffset();
			if (scopeEnd > offset)
				scope.clearFrom(offset);
		}
		if (ix <= children.size() - 1) {
			//System.out.printf("  range: %d - %d\n", ix, children.size());
			((List<Scope>) children).subList(ix, children.size()).clear();
		}
		if (getEnd().getOffset() > offset) {
			removeEnd();
			isOpen = true;
		}
	}
	
	public int compareTo(Scope o) {
		if(getStart().compareTo(o.getStart()) == 0){
			return getEnd().compareTo(o.getEnd());
		}
		return getStart().compareTo(o.getStart());
	}

	public Scope containingDoubleScope(int lineIx) {
		Scope scope = this;
		while ((scope.pattern instanceof SinglePattern || 
			      scope.isCapture || 
			      (scope.getStart().getLine() == lineIx && scope.getStart().getLineOffset() == 0)) && 
					 scope.parent != null) {
			scope = scope.parent;
		}
		return scope;
	}
	
	public boolean surfaceIdenticalTo(Scope other) {
		if (surfaceIdenticalToModuloEnding(other) &&
				getEnd().equals(other.getEnd()) &&
				getInnerEnd().equals(other.getInnerEnd()) &&
				beginMatchString.equals(other.beginMatchString)) {
			return true;
		}
		return false;
	}

	public boolean surfaceIdenticalToModuloEnding(Scope other) {
	    //System.out.printf("name: %s; other.name: %s\n", name, other.name);
	    //if (getStart() == null) {
	    //  System.out.printf("getStart() is null");
	    //}
		if (
		     ( (name == null && other.name == null) || (name != null && name.equals(other.name)) ) &&
				pattern == other.pattern &&
				getStart().equals(other.getStart()) &&
				getInnerStart().equals(other.getInnerStart()) &&
				beginMatchString.equals(other.beginMatchString)) {
			return true;
		}
		return false;
	}

	public ArrayList<Scope> scopesOnLine(int lineIx) {
		ArrayList<Scope> scopes = new ArrayList<Scope>();
		if (getStart().getLine() <= lineIx && getEnd().getLine() >= lineIx)
			scopes.add(this);
		childScopesOnLine(lineIx, scopes);
		return scopes;
	}
	
	public void childScopesOnLine(int lineIx, ArrayList<Scope> scopes) {
		for (Scope child : children) {
			if (child.getStart().getLine() <= lineIx && child.getEnd().getLine() >= lineIx) {
				scopes.add(child);
				child.childScopesOnLine(lineIx, scopes);
			}
		}
	}
	
	public ArrayList<Scope> scopesBetween(int startOffset, int endOffset) {
		ArrayList<Scope> scopes = new ArrayList<Scope>();
		if (getStart().getOffset() < endOffset && getEnd().getOffset() >= startOffset)
			scopes.add(this);
		childScopesBetween(startOffset, endOffset, scopes);
		return scopes;
	}
	
	public void childScopesBetween(int startOffset, int endOffset, ArrayList<Scope> scopes) {
		for (Scope child : children) {
			if (child.getStart().getOffset() < endOffset && child.getEnd().getOffset() >= startOffset) {
				scopes.add(child);
				child.childScopesBetween(startOffset, endOffset, scopes);
			}
		}
	}
	
	public boolean overlapsWith(Scope other) {
		// sd1    +---
		// sd2  +---
		if (getStart().compareTo(other.getStart()) >= 0) {
			if (getStart().compareTo(other.getEnd()) < 0) {
				return true;
			}
			return false;
		}

		// sd1 +---
		// sd2   +---
		if (getEnd().compareTo(other.getStart()) > 0) {
			return true;
		}
		return false;
	}

	public void addChild(Scope newChild) {
		if (children.size() == 0){
			children.add(newChild);
			return;
		}
		
		int newChildStartOffset = newChild.getStart().getOffset();

		if (children.get(0).getStart().getOffset() > newChildStartOffset){
			children.add(0, newChild);
			return;
		}

		int insertIx = 0;
		int ix = 1;
		Scope lastChild = children.get(children.size() - 1);
		
		if (lastChild.getStart().getOffset() <= newChildStartOffset) {
			insertIx = children.size();
		}
		else {
			for (Scope child : children) {
				if (child.getStart().getOffset() <= newChildStartOffset) {
					insertIx = ix;
				}
				ix++;
			}
		}
		children.add(insertIx, newChild);
	}
	
	public void removeChild(Scope child) {
		children.remove(child);
	}
	
	public Scope firstChildAfter(MateTextLocation location) {
		if (children.size() == 0)
			return null;
			
		int offset = location.getOffset();
		int ix = indexOfEarliestAfter(children, offset);
		Scope r = null;
		if (ix == -1) {
			return null;
		}
		else {
			return children.get(ix);
		}
	}
	
	public void printScopeRanges(String title, ArrayList<Scope> scopes) {
		System.out.printf("%s: ", title);
		for (Scope s : scopes) {
			System.out.printf("%d-%d, ", s.getStart().getOffset(), s.getEnd().getOffset());
		}
		System.out.printf("\n");
	}
	
	public ArrayList<Scope> deleteAnyBetweenNotIn(int startOffset, int endOffset, ArrayList<Scope> scopes) {
		//System.out.printf("deleteAnyBetweenNotIn(%d, %d)\n", startOffset, endOffset);
		//printScopeRanges("  children", children);
		//printScopeRanges("  safe", scopes);
		ArrayList<Scope> removedScopes = new ArrayList<Scope>();
		int ix, childStart;
		
		int ixEnd   = indexOfLatestBefore(children, endOffset);
		if (ixEnd == -1)
			return removedScopes;
		int ixStart = indexOfEarliestAfter(children, startOffset);
		if (ixStart == -1)
			ix = 0;
		else
			ix = ixStart;
		//System.out.printf("  start: %d, end: %d\n", ixStart, ixEnd);
		while (ix <= ixEnd) {
			Scope child = children.get(ix);
			childStart = child.getStart().getOffset();
			//System.out.printf("    checking: %d-%d\n", child.getStart().getOffset(), child.getEnd().getOffset());
			if (childStart >= startOffset && childStart < endOffset && !scopes.contains(child)) {
				removedScopes.add(child);
			}
			ix++;
		}
		children.removeAll(removedScopes);
		//printScopeRanges("  removedScopes", removedScopes);
		return removedScopes;
	}
	
	public void setStartPos(int line, int lineOffset, boolean hasLeftGravity) {
		MateTextLocation start = document.getTextLocation(line, lineOffset);
		this.range.setStart(start);
		document.addTextLocation("scopes", start);
	}

	public void setInnerStartPos(int line, int lineOffset, boolean hasLeftGravity) {
		MateTextLocation innerStart = document.getTextLocation(line, lineOffset);
		this.innerRange.setStart(innerStart);
		document.addTextLocation("scopes", innerStart);
	}

	public void setInnerEndPos(int line, int lineOffset, boolean c) {
		MateTextLocation innerEnd = document.getTextLocation(line, lineOffset);
		this.innerRange.setEnd(innerEnd);
		document.addTextLocation("scopes", innerEnd);
	}

	public void setEndPos(int line, int lineOffset, boolean c) {
		MateTextLocation end = document.getTextLocation(line, lineOffset);
		this.range.setEnd(end);
		document.addTextLocation("scopes", end);
	}
	
	public void removeEnd() {
		this.range.clearEnd();
		this.innerRange.clearEnd();
	}
	
	public int getLength(){
		return range.getLength();
	}
	
	public MateTextLocation getStart() {
		return range.getStart();
	}
	
	public MateTextLocation getEnd(){
		return range.getEnd();
	}

	public MateTextLocation getInnerStart(){
		return innerRange.getStart();
	}
		
	public MateTextLocation getInnerEnd(){
		return innerRange.getEnd();
	}
		
	public boolean contains(MateTextLocation location){
		return range.conatains(location);
	}

	public String hierarchyNames(boolean inner) {
		String selfName;
		// stdout.printf("'%s'.hierarchy_names(%s)\n", name, inner ? "true" : "false");
		if (pattern instanceof DoublePattern &&
				((DoublePattern) pattern).contentName != null &&
				inner) {
			selfName = name + " " + ((DoublePattern) pattern).contentName;
		}
		else {
			selfName = name;
		}
		if (parent != null) {
			boolean next_inner;
			if (isCapture)
				next_inner = false;
			else
				next_inner = true;
			return parent.hierarchyNames(next_inner) + " " + selfName;
		}
		else {
			return selfName;
		}
	}

	public String pretty(int indent) {
		prettyString = new StringBuilder("");
		this.indent = indent;
		for (int i = 0; i < indent; i++)
			prettyString.append("  ");
		if (this.isCapture)
			prettyString.append("c");
		else
			prettyString.append("+");
		
		if (this.name != null)
			prettyString.append(" " + this.name);
		else
			prettyString.append(" " + "[noname]");
		
		if (this.pattern instanceof DoublePattern && 
				this.isCapture == false && 
				((DoublePattern) this.pattern).contentName != null) 
			prettyString.append(" " + ((DoublePattern) this.pattern).contentName);
		prettyString.append(" (");
		prettyString.append(String.format(
				"%d,%d",
				getStart().getLine(), 
				getStart().getLineOffset()));
//		prettyString.append(getStart().getOffset());
		prettyString.append(")-(");
		prettyString.append(String.format(
				"%d,%d",
				getEnd().getLine(), 
				getEnd().getLineOffset()));
//		prettyString.append(getEnd().getOffset());
		prettyString.append(")");
		prettyString.append((isOpen ? " open" : " closed"));
		prettyString.append("\n");

		this.indent += 1;
		for (Scope child : this.children) {
			prettyString.append(child.pretty(this.indent));
		}
		
		return prettyString.toString();
	}
	

	public String nearestBackgroundColour() {
		if (parent != null) {
			return parent.nearestBackgroundColour1();
		}
		return null;
	}

	public String nearestBackgroundColour1() {
		if (bgColour != null)
			return bgColour;
		if (parent != null) {
			return parent.nearestBackgroundColour1();
		}
		return null;
	}

	public String nearestForegroundColour() {
		if (parent != null) {
			return parent.nearestForegroundColour1();
		}
		return null;
	}

	public String nearestForegroundColour1() {
		if (fgColour != null)
			return fgColour;
		if (parent != null) {
			return parent.nearestForegroundColour1();
		}
		return null;
	}
	
	public int countDescendants() {
		int i = children.size();
		for (Scope child : children) {
			i += child.countDescendants();
		}
		return i;
	}
}



