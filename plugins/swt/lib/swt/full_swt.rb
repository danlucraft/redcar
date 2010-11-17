
module Swt
  import org.eclipse.swt.SWT

  module Widgets
    import org.eclipse.swt.widgets.Button
    import org.eclipse.swt.widgets.Caret
    import org.eclipse.swt.widgets.Combo
    import org.eclipse.swt.widgets.Composite
    import org.eclipse.swt.widgets.Event
    import org.eclipse.swt.widgets.DirectoryDialog
    import org.eclipse.swt.widgets.FileDialog
    import org.eclipse.swt.widgets.List
    import org.eclipse.swt.widgets.Menu
    import org.eclipse.swt.widgets.MenuItem
    import org.eclipse.swt.widgets.MessageBox
    import org.eclipse.swt.widgets.ToolBar
    import org.eclipse.swt.widgets.ToolItem
    import org.eclipse.swt.widgets.CoolBar
    import org.eclipse.swt.widgets.CoolItem
    import org.eclipse.swt.widgets.Sash
    import org.eclipse.swt.widgets.Slider
    import org.eclipse.swt.widgets.TabFolder
    import org.eclipse.swt.widgets.TabItem
    import org.eclipse.swt.widgets.Text
    import org.eclipse.swt.widgets.ToolTip
    import org.eclipse.swt.widgets.Table
    import org.eclipse.swt.widgets.TableItem
  end

  module Custom
    import org.eclipse.swt.custom.CTabFolder
    import org.eclipse.swt.custom.CTabItem
    import org.eclipse.swt.custom.SashForm
    import org.eclipse.swt.custom.StackLayout
    import org.eclipse.swt.custom.ST
    import org.eclipse.swt.custom.StyledText
    import org.eclipse.swt.custom.TreeEditor
  end

  module DND
    import org.eclipse.swt.dnd.DND

    # Only load Clipboard in full running mode.
    import org.eclipse.swt.dnd.Clipboard unless Redcar.no_gui_mode?

    import org.eclipse.swt.dnd.Transfer
    import org.eclipse.swt.dnd.TextTransfer
    import org.eclipse.swt.dnd.FileTransfer
    import org.eclipse.swt.dnd.ByteArrayTransfer

    import org.eclipse.swt.dnd.DropTarget
    import org.eclipse.swt.dnd.DropTargetEvent
    import org.eclipse.swt.dnd.DropTargetListener

    import org.eclipse.swt.dnd.DragSource
    import org.eclipse.swt.dnd.DragSourceEvent
    import org.eclipse.swt.dnd.DragSourceListener
  end

  module Layout
    import org.eclipse.swt.layout.FillLayout
    import org.eclipse.swt.layout.GridLayout
    import org.eclipse.swt.layout.GridData
    import org.eclipse.swt.layout.RowLayout
    import org.eclipse.swt.layout.RowData
  end

  module Graphics
    import org.eclipse.swt.graphics.Color
    import org.eclipse.swt.graphics.Device
    import org.eclipse.swt.graphics.Font
    import org.eclipse.swt.graphics.GC
    import org.eclipse.swt.graphics.Point
    import org.eclipse.swt.graphics.RGB
  end

  module Events
    import org.eclipse.swt.events.KeyEvent
    import org.eclipse.swt.events.MouseListener
    import org.eclipse.swt.events.MouseTrackListener
  end

  import org.eclipse.swt.browser.Browser
  class Browser
    import org.eclipse.swt.browser.BrowserFunction
  end

  class RRunnable
    include java.lang.Runnable

    def initialize(&block)
      @block = block
    end

    def run
      @block.call
    end
  end
end

module JFace
  Dir[Redcar.asset_dir + "/jface/*.jar"].each do |jar_fn|
    require jar_fn
  end

  module Viewers
    import org.eclipse.jface.viewers.ColumnViewerToolTipSupport
    import org.eclipse.jface.viewers.TreeViewer
    import org.eclipse.jface.viewers.ITreeContentProvider
    import org.eclipse.jface.viewers.ILabelProvider
    import org.eclipse.jface.viewers.ILazyTreeContentProvider
    import org.eclipse.jface.viewers.ILabelProvider
    import org.eclipse.jface.viewers.TextCellEditor
    import org.eclipse.jface.viewers.ViewerDropAdapter
  end

  module Text
    import org.eclipse.jface.text.TextViewerUndoManager
  end

  module Dialogs
    import org.eclipse.jface.dialogs.Dialog
    import org.eclipse.jface.dialogs.InputDialog
  end
end

require 'swt/grid_data'
