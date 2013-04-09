
package com.redcareditor.application_swt;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import org.eclipse.swt.SWT;
import org.eclipse.swt.internal.C;
import org.eclipse.swt.internal.Callback;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Listener;


import org.eclipse.swt.internal.cocoa.OS;
import org.eclipse.swt.internal.cocoa.NSObject;
import org.eclipse.swt.internal.cocoa.id;
import org.eclipse.swt.internal.cocoa.NSString;


/**
 * Provide a hook to connecting the Preferences, About and Quit menu items of the Mac OS X
 * Application menu when using the SWT Cocoa bindings.
 * <p>
 * This code does not require the Cocoa SWT JAR in order to be compiled as it uses reflection to
 * access the Cocoa specific API methods. It does, however, depend on JFace (for IAction), but you
 * could easily modify the code to use SWT Listeners instead in order to use this class in SWT only
 * applications.
 * </p>
 * <p>
 * This code was influenced by the <a
 * href="http://www.simidude.com/blog/2008/macify-a-swt-application-in-a-cross-platform-way/"
 * >CarbonUIEnhancer from Agynami</a> with the implementation being modified from the <a href="http://dev.eclipse.org/viewcvs/index.cgi/org.eclipse.ui.cocoa/src/org/eclipse/ui/internal/cocoa/CocoaUIEnhancer.java"
 * >org.eclipse.ui.internal.cocoa.CocoaUIEnhancer</a>.
 * </p>
 * <p>
 * This class works with both the 32-bit and 64-bit versions of the SWT Cocoa bindings.
 * <p>
 * <p>
 * This class is released under the Eclipse Public License (<a href="http://www.eclipse.org/legal/epl-v10.html">EPL</a>).
 */
public class CocoaUIEnhancer {

    private static final long kAboutMenuItem = 0;
    private static final long kPreferencesMenuItem = 2;
    // private static final long kServicesMenuItem = 4;
    // private static final long kHideApplicationMenuItem = 6;
    private static final long kQuitMenuItem = 10;

    static long sel_toolbarButtonClicked_;
    static long sel_preferencesMenuItemSelected_;
    static long sel_aboutMenuItemSelected_;
    static Callback proc3Args;

    static Callback proc4Args;

    final private String appName;

    /**
     * Class invoked via the Callback object to run the about and preferences actions.
     * <p>
     * If you don't use JFace in your application (SWT only), change the
     * {@link org.eclipse.jface.action.IAction}s to {@link org.eclipse.swt.widgets.Listener}s.
     * </p>
     */
    private static class MenuHookObject {
        final Listener about;
        final Listener pref;

        public MenuHookObject( Listener about, Listener pref ) {
            this.about = about;
            this.pref = pref;
        }

        /**
         * Will be called on 32bit SWT.
         */
        @SuppressWarnings( "unused" )
        public int actionProc( int id, int sel, int arg0 ) {
            return (int) actionProc( (long) id, (long) sel, (long) arg0 );
        }

        /**
         * Will be called on 64bit SWT.
         */
        public long actionProc( long id, long sel, long arg0 ) {
            if ( sel == sel_aboutMenuItemSelected_ ) {
                about.handleEvent(null);
            } else if ( sel == sel_preferencesMenuItemSelected_ ) {
                pref.handleEvent(null);
            } else {
                // Unknown selection!
            }
            // Return value is not used.
            return 99;
        }
    }

    private static class OpenFileHookObject {
        final Listener openFile;

        public OpenFileHookObject( Listener openFile ) {
            this.openFile = openFile;
        }

        /**
         * Will be called on 32bit SWT.
         */
        @SuppressWarnings( "unused" )
        public int actionProc( int id, int sel, int arg0, int arg1 ) {
            return (int) actionProc( (long) id, (long) sel, (long) arg0, (long) arg1 );
        }

        /**
         * Will be called on 64bit SWT.
         */
        public long actionProc( long id, long sel, long arg0, long arg1 ) {
            if ( sel == OS.sel_application_openFile_ ) {
                System.out.println("HOORAY \\o/");
                openFile.handleEvent(null);
            } else {
                // Unknown selection!
                System.out.println("UNKNOWN SELECTION!?");
            }
            // Return value is not used.
            return 99;
        }
    }

    /**
     * Construct a new CocoaUIEnhancer.
     * 
     * @param appName
     *            The name of the application. It will be used to customize the About and Quit menu
     *            items. If you do not wish to customize the About and Quit menu items, just pass
     *            <tt>null</tt> here.
     */
    public CocoaUIEnhancer( String appName ) {
        this.appName = appName;
    }

    /**
     * Hook the given Listener to the Mac OS X application Quit menu and the IActions to the About
     * and Preferences menus.
     * 
     * @param display
     *            The Display to use.
     * @param quitListener
     *            The listener to invoke when the Quit menu is invoked.
     * @param aboutListener
     *            The listener to invoke when the About menu is invoked.
     * @param preferencesListener
     *            The listener to invoke when the Preferences menu is invoked.
     */
    public void hookApplicationMenu( Display display, Listener quitListener, Listener aboutListener,
                                     Listener preferencesListener ) {
        // This is our callbackObject whose 'actionProc' method will be called when the About or
        // Preferences menuItem is invoked.
        MenuHookObject target = new MenuHookObject( aboutListener, preferencesListener );

        try {
            // Initialize the menuItems.
            initialize( target );
        } catch ( Exception e ) {
            throw new IllegalStateException( e );
        }

        // Connect the quit/exit menu.
        if ( !display.isDisposed() ) {
            display.addListener( SWT.Close, quitListener );
        }

        // Schedule disposal of callback object
        display.disposeExec( new Runnable() {
            public void run() {
                invoke( proc3Args, "dispose" );
            }
        } );
    }

    public void hookApplicationOpenFile( Display display, Listener openFileListener) {
        OpenFileHookObject target = new OpenFileHookObject( openFileListener );

        try {
            // Initialize the openFile.
            initialize( target );
        } catch ( Exception e ) {
            throw new IllegalStateException( e );
        }

        // Schedule disposal of callback object
        display.disposeExec( new Runnable() {
            public void run() {
                proc4Args.dispose();
            }
        } );
    }

    private void initialize( MenuHookObject callbackObject )
            throws Exception {

        Class<?> osCls = classForName( "org.eclipse.swt.internal.cocoa.OS" );

        // Register names in objective-c.
        if ( sel_toolbarButtonClicked_ == 0 ) {
            // sel_toolbarButtonClicked_ = registerName( osCls, "toolbarButtonClicked:" ); //$NON-NLS-1$
            sel_preferencesMenuItemSelected_ = registerName( osCls, "preferencesMenuItemSelected:" ); //$NON-NLS-1$
            sel_aboutMenuItemSelected_ = registerName( osCls, "aboutMenuItemSelected:" ); //$NON-NLS-1$
        }

        // Create an SWT Callback object that will invoke the actionProc method of our internal
        // callbackObject.
        proc3Args = new Callback( callbackObject, "actionProc", 3 ); //$NON-NLS-1$
        Method getAddress = Callback.class.getMethod( "getAddress", new Class[0] );
        Object object = getAddress.invoke( proc3Args, (Object[]) null );
        long proc3 = convertToLong( object );
        if ( proc3 == 0 ) {
            SWT.error( SWT.ERROR_NO_MORE_CALLBACKS );
        }

        Class<?> nsmenuCls = classForName( "org.eclipse.swt.internal.cocoa.NSMenu" );
        Class<?> nsmenuitemCls = classForName( "org.eclipse.swt.internal.cocoa.NSMenuItem" );
        Class<?> nsstringCls = classForName( "org.eclipse.swt.internal.cocoa.NSString" );
        Class<?> nsapplicationCls = classForName( "org.eclipse.swt.internal.cocoa.NSApplication" );

        // Instead of creating a new delegate class in objective-c,
        // just use the current SWTApplicationDelegate. An instance of this
        // is a field of the Cocoa Display object and is already the target
        // for the menuItems. So just get this class and add the new methods
        // to it.
        object = invoke( osCls, "objc_lookUpClass", new Object[] { "SWTApplicationDelegate" } );
        long cls = convertToLong( object );

        // Add the action callbacks for Preferences and About menu items.
        invoke( osCls, "class_addMethod", new Object[] {
                                                        wrapPointer( cls ),
                                                        wrapPointer( sel_preferencesMenuItemSelected_ ),
                                                        wrapPointer( proc3 ),
                                                        "@:@" } ); //$NON-NLS-1$
        invoke( osCls, "class_addMethod", new Object[] {
                                                        wrapPointer( cls ),
                                                        wrapPointer( sel_aboutMenuItemSelected_ ),
                                                        wrapPointer( proc3 ),
                                                        "@:@" } ); //$NON-NLS-1$

        // Get the Mac OS X Application menu.
        Object sharedApplication = invoke( nsapplicationCls, "sharedApplication" );
        Object mainMenu = invoke( sharedApplication, "mainMenu" );
        Object mainMenuItem = invoke( nsmenuCls, mainMenu, "itemAtIndex", new Object[] { wrapPointer( 0 ) } );
        Object appMenu = invoke( mainMenuItem, "submenu" );

        // Create the About <application-name> menu command
        Object aboutMenuItem =
            invoke( nsmenuCls, appMenu, "itemAtIndex", new Object[] { wrapPointer( kAboutMenuItem ) } );
        if ( appName != null ) {
            Object nsStr = invoke( nsstringCls, "stringWith", new Object[] { "About " + appName } );
            invoke( nsmenuitemCls, aboutMenuItem, "setTitle", new Object[] { nsStr } );
        }
        // Rename the quit action.
        if ( appName != null ) {
            Object quitMenuItem =
                invoke( nsmenuCls, appMenu, "itemAtIndex", new Object[] { wrapPointer( kQuitMenuItem ) } );
            Object nsStr = invoke( nsstringCls, "stringWith", new Object[] { "Quit " + appName } );
            invoke( nsmenuitemCls, quitMenuItem, "setTitle", new Object[] { nsStr } );
        }

        // Enable the Preferences menuItem.
        Object prefMenuItem =
            invoke( nsmenuCls, appMenu, "itemAtIndex", new Object[] { wrapPointer( kPreferencesMenuItem ) } );
        invoke( nsmenuitemCls, prefMenuItem, "setEnabled", new Object[] { true } );

        // Set the action to execute when the About or Preferences menuItem is invoked.
        //
        // We don't need to set the target here as the current target is the SWTApplicationDelegate
        // and we have registerd the new selectors on it. So just set the new action to invoke the
        // selector.
        invoke( nsmenuitemCls, prefMenuItem, "setAction",
                new Object[] { wrapPointer( sel_preferencesMenuItemSelected_ ) } );
        invoke( nsmenuitemCls, aboutMenuItem, "setAction",
                new Object[] { wrapPointer( sel_aboutMenuItemSelected_ ) } );
    }

    private void initialize( OpenFileHookObject callbackObject )
            throws Exception {

        Class<?> osCls = classForName( "org.eclipse.swt.internal.cocoa.OS" );
        Class<?> nsapplicationCls = classForName( "org.eclipse.swt.internal.cocoa.NSApplication" );

        NSObject sharedApplication = (NSObject)invoke( nsapplicationCls, "sharedApplication" );

        Object appDelegate = invoke( osCls, "objc_msgSend", new Object[] {
            wrapPointer( convertToLong(sharedApplication.id) ),
            OS.sel_delegate
        });

        long appDelegatePtr = convertToLong(appDelegate);

        Object appDelegateCls = invoke( osCls, "object_getClass", new Object[] {
            wrapPointer( appDelegatePtr ),
        });

        long appDelegateClsPtr = convertToLong( appDelegateCls );

        if (appDelegatePtr == 0) {
            System.out.println("App delegate was initially set to null");
            Object object = invoke( osCls, "objc_lookUpClass", new Object[] { "SWTApplicationDelegate" } );
            appDelegateClsPtr = convertToLong( object );

            appDelegate = invoke( osCls, "objc_msgSend", new Object[] {
                wrapPointer( appDelegateClsPtr ),
                wrapPointer( OS.sel_alloc )
            });

            invoke( osCls, "objc_msgSend", new Object[] {
                wrapPointer( convertToLong(appDelegate) ),
                wrapPointer( OS.sel_init )
            });

            invoke( osCls, "objc_msgSend", new Object[] {
                wrapPointer( convertToLong(sharedApplication.id) ),
                OS.sel_setDelegate_,
                wrapPointer( convertToLong(appDelegate) )
            });
        }

        // Create an SWT Callback object that will invoke the actionProc method of our internal
        // callbackObject.
        proc4Args = new Callback( callbackObject, "actionProc", 4 );
        long proc4 = (long)proc4Args.getAddress();

        if ( proc4 == 0 ) {
            SWT.error( SWT.ERROR_NO_MORE_CALLBACKS );
        }

        // Add the action callbacks for opening a file via drag & drop
        Boolean result = (Boolean)invoke( osCls, "class_addMethod", new Object[] {
                                                        wrapPointer( appDelegateClsPtr ),
                                                        wrapPointer( OS.sel_application_openFile_ ),
                                                        wrapPointer( proc4 ),
                                                        "@:@@" } );

        if (!result) {
            // Adding the callback method was unsuccesfull, likely due to the fact that the
            // method probably already exists. So we set the implementation instead.
            Object appDelegateMethod = invoke( osCls, "class_getInstanceMethod", new Object[] {
                wrapPointer( appDelegateClsPtr ),
                wrapPointer( OS.sel_application_openFile_ )
            });

            long appDelegateMethodPtr = convertToLong(appDelegateMethod);
            System.out.println("App delegate method ptr: " + appDelegateMethodPtr);

            Object oldMethod = invoke( osCls, "method_setImplementation", new Object[] {
                wrapPointer( appDelegateMethodPtr ),
                wrapPointer( proc4 )
            });

            System.out.println("Old method: " + convertToLong(oldMethod));
            System.out.println("Current method:" + wrapPointer(proc4));

            // TODO: dispose of oldMethod
        }
    }

    private long registerName( Class<?> osCls, String name )
            throws IllegalArgumentException, SecurityException, IllegalAccessException,
            InvocationTargetException, NoSuchMethodException {
        Object object = invoke( osCls, "sel_registerName", new Object[] { name } );
        return convertToLong( object );
    }

    private long convertToLong( Object object ) {
        if ( object instanceof Integer ) {
            Integer i = (Integer) object;
            return i.longValue();
        }
        if ( object instanceof Long ) {
            Long l = (Long) object;
            return l.longValue();
        }
        return 0;
    }

    private static Object wrapPointer( long value ) {
        Class<?> PTR_CLASS = C.PTR_SIZEOF == 8 ? long.class : int.class;
        if ( PTR_CLASS == long.class ) {
            return new Long( value );
        } else {
            return new Integer( (int) value );
        }
    }

    private static Object invoke( Class<?> clazz, String methodName, Object[] args ) {
        return invoke( clazz, null, methodName, args );
    }

    private static Object invoke( Class<?> clazz, Object target, String methodName, Object[] args ) {
        try {
            Class<?>[] signature = new Class<?>[args.length];
            for ( int i = 0; i < args.length; i++ ) {
                Class<?> thisClass = args[i].getClass();
                if ( thisClass == Integer.class )
                    signature[i] = int.class;
                else if ( thisClass == Long.class )
                    signature[i] = long.class;
                else if ( thisClass == Byte.class )
                    signature[i] = byte.class;
                else if ( thisClass == Boolean.class )
                    signature[i] = boolean.class;
                else
                    signature[i] = thisClass;
            }
            Method method = clazz.getMethod( methodName, signature );
            return method.invoke( target, args );
        } catch ( Exception e ) {
            throw new IllegalStateException( e );
        }
    }

    private Class<?> classForName( String classname ) {
        try {
            Class<?> cls = Class.forName( classname );
            return cls;
        } catch ( ClassNotFoundException e ) {
            throw new IllegalStateException( e );
        }
    }

    private Object invoke( Class<?> cls, String methodName ) {
        return invoke( cls, methodName, (Class<?>[]) null, (Object[]) null );
    }

    private Object invoke( Class<?> cls, String methodName, Class<?>[] paramTypes, Object... arguments ) {
        try {
            Method m = cls.getDeclaredMethod( methodName, paramTypes );
            return m.invoke( null, arguments );
        } catch ( Exception e ) {
            throw new IllegalStateException( e );
        }
    }

    private Object invoke( Object obj, String methodName ) {
        return invoke( obj, methodName, (Class<?>[]) null, (Object[]) null );
    }

    private Object invoke( Object obj, String methodName, Class<?>[] paramTypes, Object... arguments ) {
        try {
            Method m = obj.getClass().getDeclaredMethod( methodName, paramTypes );
            return m.invoke( obj, arguments );
        } catch ( Exception e ) {
            throw new IllegalStateException( e );
        }
    }
}
