public class CucumberRunner implements IApplication {

    public Object start(IApplicationContext context) throws Exception {
        Bundle bundle = Platform.getBundle("org.jruby.jruby");

        URL jrubyHome = FileLocator.toFileURL(bundle.getEntry("/META-INF/jruby.home"));

        RubyInstanceConfig config = new RubyInstanceConfig();
        config.setJRubyHome(jrubyHome.toString());
        Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(), config);
        RubyRuntimeAdapter evaler = JavaEmbedUtils.newRuntimeAdapter();
        evaler.eval(runtime, "p 'Hello, Eclipse World'");
        JavaEmbedUtils.terminate(runtime);

        return EXIT_OK;
    }

    public void stop() {
        // do nothing
    }
}