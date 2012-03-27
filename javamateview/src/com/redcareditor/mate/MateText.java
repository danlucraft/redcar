package com.redcareditor.mate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;
import java.util.logging.Handler;
import java.util.logging.ConsoleHandler;
import java.util.logging.Level;

import org.eclipse.jface.text.*;
import org.eclipse.jface.text.source.*;
import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.StyledText;
import org.eclipse.swt.events.*;
import org.eclipse.swt.graphics.*;
import org.eclipse.swt.layout.*;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Canvas;
import org.eclipse.jface.text.presentation.IPresentationReconciler;
import org.eclipse.jface.text.presentation.PresentationReconciler;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.runtime.*;
import org.eclipse.core.runtime.jobs.*;

import com.redcareditor.mate.colouring.Colourer;
import com.redcareditor.mate.colouring.swt.SwtColourer;
import com.redcareditor.mate.document.MateDocument;
import com.redcareditor.mate.document.MateTextLocation;
import com.redcareditor.mate.document.swt.SwtMateTextLocation;
import com.redcareditor.mate.document.swt.SwtMateDocument;
import com.redcareditor.mate.undo.MateTextUndoManager;
import com.redcareditor.mate.undo.swt.SwtMateTextUndoManager;
import com.redcareditor.mate.WhitespaceCharacterPainter;
import com.redcareditor.mate.LineNumberRulerColumn;
import com.redcareditor.onig.NullRx;
import com.redcareditor.onig.Rx;
import com.redcareditor.theme.Theme;
import com.redcareditor.theme.ThemeManager;
import com.redcareditor.util.SingleLineFormatter;

public class MateText {
    public static String VERSION = "0.11";
	public Parser parser;
	public Colourer colourer;
	public Logger logger;

	static private Handler _consoleHandler;
	static public Handler consoleHandler() {
		if (_consoleHandler == null) {
			_consoleHandler = new ConsoleHandler();
			_consoleHandler.setFormatter(new SingleLineFormatter());
		}
		return _consoleHandler;
	}

	/* components plugged together */
	public SourceViewer viewer;
	private IDocument document;
	private CompositeRuler compositeRuler;
    public AnnotationRulerColumn annotationRuler;
	private LineNumberRulerColumn lineNumbers;
	private SwtMateDocument mateDocument;

	private MateTextUndoManager undoManager;
	private List<IGrammarListener> grammarListeners;

	private boolean singleLine;
	private WhitespaceCharacterPainter whitespaceCharacterPainter;
    private boolean showingInvisibles;

    private static HashMap<String, Image> annotationImages = new HashMap<String, Image>();

    // annotation model
    private AnnotationModel fAnnotationModel = new AnnotationModel();
    private IAnnotationAccess fAnnotationAccess;
    private AnnotationPainter annotationPainter;
    private MouseListener annotationMouseListener;
    private ColorCache cc;

    private int marginColumn = -1;

	public MateText(Composite parent) {
		this(parent, false);
	}

	public MateText(Composite parent, boolean thisSingleLine) {
		singleLine = thisSingleLine;
		document = new Document();
		if (singleLine)
			createSingleLineSourceViewer(parent);
		else
			createSourceViewer(parent);

		whitespaceCharacterPainter = new WhitespaceCharacterPainter(viewer);
		showingInvisibles = false;

		colourer = new SwtColourer(this);
		mateDocument = new SwtMateDocument(this);
		grammarListeners = new ArrayList<IGrammarListener>();
		getTextWidget().setLeftMargin(5);
		logger = Logger.getLogger("JMV.MateText");
		logger.setUseParentHandlers(false);
		logger.setLevel(Level.SEVERE);
		for (Handler h : logger.getHandlers()) {
			logger.removeHandler(h);
		}
		logger.addHandler(MateText.consoleHandler());
		logger.info("Created MateText");
	}

	private void createSingleLineSourceViewer(Composite parent) {
		viewer = new SourceViewer(parent, null, SWT.FULL_SELECTION | SWT.HORIZONTAL | SWT.VERTICAL | SWT.SINGLE);
		viewer.setDocument(document);
	}

	private void createSourceViewer(Composite parent) {
		fAnnotationAccess = new AnnotationMarkerAccess();

		cc = new ColorCache();

		compositeRuler = new CompositeRuler();
		annotationRuler = new AnnotationRulerColumn(fAnnotationModel, 16, fAnnotationAccess);
		compositeRuler.setModel(fAnnotationModel);

		// add what types are show on the different rulers

		lineNumbers = new LineNumberRulerColumn();
		compositeRuler.addDecorator(0, lineNumbers);
		compositeRuler.addDecorator(0, annotationRuler);

		viewer = new SourceViewer(parent, compositeRuler, SWT.FULL_SELECTION | SWT.HORIZONTAL | SWT.VERTICAL);
		viewer.setDocument(document, fAnnotationModel);

		// hover manager that shows text when we hover
		AnnotationHover ah = new AnnotationHover();
		AnnotationConfiguration ac = new AnnotationConfiguration();
		AnnotationBarHoverManager fAnnotationHoverManager = new AnnotationBarHoverManager(compositeRuler, viewer, ah, ac);
		fAnnotationHoverManager.install(annotationRuler.getControl());

		// to paint the annotations
		annotationPainter = new AnnotationPainter(viewer, fAnnotationAccess);

		// this will draw the squigglies under the text
		viewer.addPainter(annotationPainter);

		createAnnotationMouseListener();
	}

	private void createAnnotationMouseListener() {
		annotationMouseListener = new MouseListener() {
			public void mouseUp(MouseEvent event) {
				int lineNumber = annotationRuler.toDocumentLineNumber(event.y);
				for (IAnnotationAreaListener l : annotationListeners) {
					l.mouseClick(lineNumber);
				}
			}

			public void mouseDown(MouseEvent event) {
				int lineNumber = annotationRuler.toDocumentLineNumber(event.y);
				System.out.printf("mouseDown line: %d\n", lineNumber);
			}

			public void mouseDoubleClick(MouseEvent event) {
				int lineNumber = annotationRuler.toDocumentLineNumber(event.y);
				System.out.printf("doubleClick line: %d\n", lineNumber);
				for (IAnnotationAreaListener l : annotationListeners) {
					l.mouseDoubleClick(lineNumber);
				}
			}
		};
		annotationRuler.getControl().addMouseListener(annotationMouseListener);

	}

	public int getMarginColumn() {
		return marginColumn;
	}

	public void setMarginColumn(int val) {
		this.marginColumn = val;
		redraw();
	}

    public void addAnnotationType(String type, String imagePath, RGB rgb) {
        if (singleLine) return;

        annotationRuler.addAnnotationType(type);
        annotationPainter.addAnnotationType(type);
		annotationPainter.setAnnotationTypeColor(type, new Color(Display.getDefault(), rgb));
        MateText.annotationImages.put(type, new Image(Display.getDefault(), imagePath));
    }

    public MateAnnotation addAnnotation(String type, int line, String text, int start, int length) {
        if (singleLine) return null;

        MateAnnotation mateAnnotation = new MateAnnotation(type, line, text);
		fAnnotationModel.addAnnotation(mateAnnotation, new Position(start, length));
        return mateAnnotation;
    }

    public ArrayList<MateAnnotation> annotations() {
        ArrayList<MateAnnotation> result = new ArrayList<MateAnnotation>();

        Iterator i = fAnnotationModel.getAnnotationIterator();
        while (i.hasNext()) {
            MateAnnotation next = (MateAnnotation) i.next();
            result.add(next);
        }
        return result;
    }

    public ArrayList<MateAnnotation> annotationsOnLine(int line) {
        ArrayList<MateAnnotation> result = new ArrayList<MateAnnotation>();

        StyledText text = getTextWidget();
        int startOffset = text.getOffsetAtLine(line);
        int endOffset;
        if (line == text.getLineCount() - 1)
            endOffset = text.getCharCount();
        else
            endOffset = text.getOffsetAtLine(line + 1);

        Iterator i = fAnnotationModel.getAnnotationIterator(startOffset, endOffset - startOffset, false, true);
        while (i.hasNext()) {
            MateAnnotation next = (MateAnnotation) i.next();
            result.add(next);
        }
        return result;
    }

    public void removeAnnotation(MateAnnotation ann) {
        fAnnotationModel.removeAnnotation(ann);
    }

    public void removeAllAnnotations() {
        fAnnotationModel.removeAllAnnotations();
    }

    private ArrayList<IAnnotationAreaListener> annotationListeners =
        new ArrayList<IAnnotationAreaListener>();

    public void addAnnotationListener(IAnnotationAreaListener listener) {
        annotationListeners.add(listener);
    }

    public ArrayList<IAnnotationAreaListener> getAnnotationListeners() {
        return annotationListeners;
    }

    public void removeAnnotationListener(IAnnotationAreaListener listener) {
        annotationListeners.remove(listener);
    }

    public void setLineNumbersVisible(boolean val) {
        if (isSingleLine()) return;
        redrawRuler(val, getAnnotationsVisible());
    }

	// the annotationRuler doesn't seem to like being added/removed
	// (images don't draw), so it's always visible for now.
	//public void setAnnotationsVisible(boolean val) {
    //    if (isSingleLine()) return;
    //    redrawRuler(getLineNumbersVisible(), val);
	//}

    public boolean getLineNumbersVisible() {
        if (isSingleLine()) return false;
        Iterator iterator = compositeRuler.getDecoratorIterator();
        while (iterator.hasNext())
            if (((IVerticalRulerColumn) iterator.next()) == lineNumbers)
                return true;
        return false;
    }

    public boolean getAnnotationsVisible() {
        Iterator iterator = compositeRuler.getDecoratorIterator();
        while (iterator.hasNext())
            if (((IVerticalRulerColumn) iterator.next()) == annotationRuler)
                return true;
        return false;
    }

    private void redrawRuler(boolean showLineNumbers, boolean showAnnotations) {
        compositeRuler.removeDecorator(lineNumbers);
		if (showLineNumbers)
			compositeRuler.addDecorator(1, (IVerticalRulerColumn) lineNumbers);
		compositeRuler.relayout();
	}

	public boolean isSingleLine() {
		return singleLine;
	}

	public void showInvisibles(boolean should) {
		if (should) {
			showingInvisibles = true;
			viewer.addPainter(whitespaceCharacterPainter);
		} else {
			showingInvisibles = false;
			viewer.removePainter(whitespaceCharacterPainter);
		}
	}

	public boolean isShowingInvisibles() {
		return showingInvisibles;
	}

	public void attachUpdater() {

	}

	public boolean getWordWrap() {
		return getTextWidget().getWordWrap();
	}

	public void setWordWrap(boolean val) {
		getTextWidget().setWordWrap(val);
	}

	public String grammarName() {
		return parser.grammar.name;
	}

	public StyledText getTextWidget() {
		return viewer.getTextWidget();
	}

	public IDocument getDocument() {
		return document;
	}

	public MateDocument getMateDocument() {
		return mateDocument;
	}

	public StyledText getControl() {
		return viewer.getTextWidget();
	}

	public boolean shouldColour() {
		return parser.shouldColour();
	}

	public String scopeAt(int line, int line_offset) {
		return parser.root.scopeAt(line, line_offset).hierarchyNames(true);
	}

	// Sets the grammar explicitly by name.
	// TODO: restore the uncolouring stuff
	public boolean setGrammarByName(String name) {
		// System.out.printf("setGrammarByName(%s)\n", name);
		if (this.parser != null && this.parser.grammar.name.equals(name))
			return true;

		for (Bundle bundle : Bundle.getBundles()) {
			for (Grammar grammar : bundle.getGrammars()) {
				if (grammar.name.equals(name)) {
					if (this.parser != null) {
						this.parser.close();
					}
					this.parser = new Parser(grammar, this);
					if (colourer != null) {
						colourer.setGlobalColours();
					}
					getMateDocument().reparseAll();
					for (IGrammarListener grammarListener : grammarListeners) {
						grammarListener.grammarChanged(grammar.name);
					}
					return true;
				}
			}
		}
		return false;
	}

	// Sets the grammar by the file extension. If unable to find
	// a grammar, sets the grammar to null. Returns the grammar
	// name or null.
	public String setGrammarByFilename(String fileName) {
		String bestName = null;
		long bestLength = 0;
		for (Bundle bundle : Bundle.getBundles()) {
			for (Grammar grammar : bundle.getGrammars()) {
				if (grammar.fileTypes != null) {
					for (String ext : grammar.fileTypes) {
						if (fileName.endsWith(ext) && (bestName == null || ext.length() > bestLength)) {
							bestName = grammar.name;
							bestLength = ext.length();
						}
					}
				}
			}
		}
		if (bestName != null) {
			if (this.parser == null || this.parser.grammar.name != bestName) {
				setGrammarByName(bestName);
			}
			return bestName;
		}
		return null;
	}

	// Sets the grammar by examining the first line. If unable to find
	// a grammar, sets the grammar to null. Returns the grammar
	// name or null.
	public String setGrammarByFirstLine(String firstLine) {
		Rx re;
		for (Bundle bundle : Bundle.getBundles()) {
			for (Grammar grammar : bundle.getGrammars()) {
				re = grammar.firstLineMatch;
				if (re instanceof NullRx) {
				} else {
					if (re.search(firstLine, 0, (int) firstLine.length()) != null) {
						setGrammarByName(grammar.name);
						return grammar.name;
					}
				}
			}
		}
		return null;
	}

	public boolean setThemeByName(String name) {
		for (Theme theme : ThemeManager.themes) {
			if (theme.name.equals(name)) {
				this.colourer.setTheme(theme);
				return true;
			}
		}
		return false;
	}

	public void setFont(String name, int size) {
		Font font = new Font(Display.getCurrent(), name, size, 0);
		viewer.getTextWidget().setFont(font);
        if (!singleLine)
    		lineNumbers.setFont(font);
		if (getLineNumbersVisible()){
			redrawRuler(true, getAnnotationsVisible());
		}
	}

	@SuppressWarnings("unchecked")
	public void setGutterBackground(Color color) {
        if (singleLine) return;
		lineNumbers.setBackground(color);
	}

	public void setGutterForeground(Color color) {
        if (singleLine) return;
		lineNumbers.setForeground(color);
	}

	public void addGrammarListener(IGrammarListener listener) {
		grammarListeners.add(listener);
	}

	public void removeGrammarListener(IGrammarListener listener) {
		grammarListeners.remove(listener);
	}

	public void redraw() {
		// SwtMateTextLocation startLocation = new SwtMateTextLocation(0, getMateDocument());
		// SwtMateTextLocation endLocation = new SwtMateTextLocation(0 + getTextWidget().getCharCount(), getMateDocument());
		getTextWidget().redraw();
	}

	class AnnotationConfiguration implements IInformationControlCreator {
		public IInformationControl createInformationControl(Shell shell) {
			return new DefaultInformationControl(shell);
		}
	}

	class ColorCache implements ISharedTextColors {
		public Color getColor(RGB rgb) {
			return new Color(Display.getDefault(), rgb);
		}

		public void dispose() {
		}
	}

	class AnnotationMarkerAccess implements IAnnotationAccess, IAnnotationAccessExtension {
		public Object getType(Annotation annotation) {
			return annotation.getType();
		}

		public boolean isMultiLine(Annotation annotation) {
			return true;
		}

		public boolean isTemporary(Annotation annotation) {
			return !annotation.isPersistent();
		}

		public String getTypeLabel(Annotation annotation) {
			if (annotation instanceof MateAnnotation)
				return "Errors";

			return null;
		}

		public int getLayer(Annotation annotation) {
			if (annotation instanceof MateAnnotation)
				return ((MateAnnotation)annotation).getLayer();

			return 0;
        }

		public void paint(Annotation annotation, GC gc, Canvas canvas, Rectangle bounds) {
			ImageUtilities.drawImage(((MateAnnotation)annotation).getImage(), gc, canvas, bounds, SWT.CENTER, SWT.TOP);
		}

		public boolean isPaintable(Annotation annotation) {
			if (annotation instanceof MateAnnotation)
				return ((MateAnnotation)annotation).getImage() != null;

			return false;
		}

		public boolean isSubtype(Object annotationType, Object potentialSupertype) {
			if (annotationType.equals(potentialSupertype))
				return true;

			return false;

		}

		public Object[] getSupertypes(Object annotationType) {
			return new Object[0];
		}
	}

	// annotation hover manager
	class AnnotationHover implements IAnnotationHover, ITextHover {
		public String getHoverInfo(ISourceViewer sourceViewer, int lineNumber) {
			Iterator ite;
			int startOffset;
			int endOffset;
			StyledText text = getTextWidget();
      try {
				if (lineNumber < 0 || lineNumber >= text.getLineCount()) return null;
				startOffset = text.getOffsetAtLine(lineNumber);
				if (lineNumber == text.getLineCount() - 1) {
					endOffset = text.getCharCount();
				} else {
					endOffset = text.getOffsetAtLine(lineNumber + 1);
				}
				ite = fAnnotationModel.getAnnotationIterator(
					startOffset, endOffset - startOffset, false, true);
			} catch(java.lang.IllegalArgumentException e) {
				System.out.printf("warning: got java.lang.IllegalArgumentException in AnnotationHover#getHoverInfo(%d). lineCount was %d\n", lineNumber, text.getLineCount());
				return "";
			}

			ArrayList all = new ArrayList();

			while (ite.hasNext()) {
				Annotation a = (Annotation) ite.next();
				if (a instanceof MateAnnotation) {
					all.add(((MateAnnotation)a).getText());
				}
			}

			StringBuffer total = new StringBuffer();
			for (int x = 0; x < all.size(); x++) {
				String str = (String) all.get(x);
				total.append(" " + str + (x == (all.size()-1) ? "" : "\n"));
			}

			return total.toString();
		}

		public String getHoverInfo(ITextViewer textViewer, IRegion hoverRegion) {
			return null;
		}

		public IRegion getHoverRegion(ITextViewer textViewer, int offset) {
			return null;
		}
	}

    class MateAnnotation extends Annotation {
		private IMarker marker;
		private String text;
		private int line;
		private Position position;
        private String type;

		public MateAnnotation(IMarker marker) {
			this.marker = marker;
		}

		public MateAnnotation(String type, int line, String text) {
			super(type, true, null);
			this.marker = null;
			this.line = line;
			this.text = text;
            this.type = type;
		}

		public IMarker getMarker() {
			return marker;
		}

		public int getLine() {
			return line;
		}

		public String getText() {
			return text;
		}

		public Image getImage() {
			return MateText.annotationImages.get(this.type);
		}

		public int getLayer() {
			return 3;
		}

		public String getType() {
			return type;
		}

		public Position getPosition() {
			return position;
		}

		public void setPosition(Position position) {
			this.position = position;
		}
	}

	// See the table in the comment for columnOfLineOffset. This method translates from
	// column to lineOffset in that table.
	public static int lineOffsetOfColumn(String line, int targetColumn, int tabWidth) {
		int offset = 0;
		int newOffset = 0;
		int column = 0;
		int prevOffset = 0;
		int prevColumn = 0;
		while ((newOffset = line.indexOf("\t", offset)) != -1) {
			newOffset++;
			prevOffset = offset;
			prevColumn = column;
			column += newOffset - offset + tabWidth - 1;
			offset = newOffset;
			if (column > targetColumn)
				return prevOffset + (targetColumn - prevColumn);
			else if (column == targetColumn)
				return offset;
		}
		return offset + targetColumn - column;
	}

	// if line is "\t\tasd", tab width is 4, then
	//
	// lineOffset, column
	// 0           0
	// 1           4
	// 2           8
	// 3           9
	// 4           10
	// 5           11
	// 6           12 (note past the end of the string)
	//
	// This function translates from lineOffset to column
	public static int columnOfLineOffset(String line, int lineOffset, int tabWidth) {
		int stringOffset = Math.max(lineOffset, line.length());
		String before = line.substring(0, stringOffset);
		int length = before.length();
		return (length + (tabWidth - 1)*countMatches(before, "\t"));
	}

	private static boolean isEmpty(String cs) {
		return cs == null || cs.length() == 0;
	}

	private static int countMatches(String str, String sub) {
		if (isEmpty(str) || isEmpty(sub)) {
			return 0;
		}
		int count = 0;
		int idx = 0;
		while ((idx = str.indexOf(sub, idx)) != -1) {
			count++;
			idx += sub.length();
		}
		return count;
	}
//
}