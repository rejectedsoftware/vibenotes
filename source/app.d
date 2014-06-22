import vibenotes.vibenotes;
import vibenotes.broadcast;

import vibe.core.log;
import vibe.http.fileserver;
import vibe.http.server : listenHTTP, HTTPServerSettings;
import vibe.http.router : URLRouter;
import vibe.http.session : MemorySessionStore;
import vibe.web.web : registerWebInterface;


shared static this()
{
	auto router = new URLRouter;
	registerWebInterface(router, new VibeNotesWeb);
	router.get("*", serveStaticFiles("public/"));

	auto settings = new HTTPServerSettings;
	settings.sessionStore = new MemorySessionStore();
	settings.port = 8080;

	listenHTTP(settings, router);
}
