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
	
	private void home(HTTPServerRequest req, HTTPServerResponse res)
	{
		if( auto pn = "name" in req.query )
			res.redirect("/n/"~*pn);
		else
			res.renderCompat!("home.dl", HTTPServerRequest, "req", string[], "channels")(Variant(req), Variant(m_broadcastService.channels));
	}

	private void editor(HTTPServerRequest req, HTTPServerResponse res)
	{
		res.renderCompat!("editor.dl", HTTPServerRequest, "req")(Variant(req));
	}

	private void logout(HTTPServerRequest req, HTTPServerResponse res)
	{
		if (req.session) {
			res.terminateSession();
		} 
		res.renderCompat!("login.dl")();
	}

	private void login(HTTPServerRequest req, HTTPServerResponse res)
	{
		auto session = res.startSession();
		session["username"] = req.form["username"];
		session["password"] = req.form["password"];
		res.redirect("/");
	}

	private void error(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
	{
		res.renderCompat!("login.dl", HTTPServerErrorInfo, "error")(Variant(error));
	}
}

void registerVibeNotes(UrlRouter router) 
{
	new VibeNotes(router);
}
