module vibenotes.vibenotes;

import vibe.d;
import vibenotes.broadcast;

import std.functional;

class VibeNotes {

	private {
		WebSocketBroadcastService m_broadcastService;
	}
	
	this(UrlRouter router) {	
		m_broadcastService = new WebSocketBroadcastService();
		router.get("/", &home);
		router.get("/login", &logout);
		router.post("/login", &login);
		router.get("/n/:name", &editor);
		router.get("/n/:channel/ws", &m_broadcastService.handleRequest);
		router.get("*", serveStaticFiles("./public/"));
	}
	
	private void home(HttpServerRequest req, HttpServerResponse res)
	{
		if( auto pn = "name" in req.query )
			res.redirect("/n/"~*pn);
		else
			res.renderCompat!("home.dl", HttpServerRequest, "req", string[], "channels")(Variant(req), Variant(m_broadcastService.channels));
	}

	private void editor(HttpServerRequest req, HttpServerResponse res)
	{
		res.renderCompat!("editor.dl", HttpServerRequest, "req")(Variant(req));
	}

	private void logout(HttpServerRequest req, HttpServerResponse res)
	{
		if (req.session) {
			res.terminateSession();
		} 
		res.renderCompat!("login.dl")();
	}

	private void login(HttpServerRequest req, HttpServerResponse res)
	{
		auto session = res.startSession();
		session["username"] = req.form["username"];
		session["password"] = req.form["password"];
		res.redirect("/");
	}

	private void error(HttpServerRequest req, HttpServerResponse res, HttpServerErrorInfo error)
	{
		res.renderCompat!("login.dl", HttpServerErrorInfo, "error")(Variant(error));
	}
}

void registerVibeNotes(UrlRouter router) 
{
	new VibeNotes(router);
}
