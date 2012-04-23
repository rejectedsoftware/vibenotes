import vibe.d;
import vibenotes.vibenotes;

static this() {
	setLogLevel(LogLevel.Info);
	
	auto router = new UrlRouter;
	registerVibeNotes(router);
	
	auto settings = new HttpServerSettings;
	settings.sessionStore = new MemorySessionStore();
	settings.port = 8080;
	
	listenHttp(settings, router);
}
