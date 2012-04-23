import vibe.vibe;

import vibenotes.vibenotes;

int main()
{
	setLogLevel(LogLevel.Info);
	
	auto router = new UrlRouter;
	registerVibeNotes(router);
	
	auto settings = new HttpServerSettings;
	settings.sessionStore = new MemorySessionStore();
	settings.port = 8080;
	settings.errorPageHandler = toDelegate(&error);
	
	listenHttp(settings, router);
	
	return start();
}
