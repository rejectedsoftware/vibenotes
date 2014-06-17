module vibenotes.vibenotes;

class VibeNotesWeb {
	import vibe.http.server:HTTPServerResponse,HTTPServerRequest,enforceHTTP,HTTPStatus;
	import vibe.http.websockets:handleWebSockets;
	import vibe.web.common:contentType,path,ContentTypeAttribute,PathAttribute;
	import vibe.web.web:SessionVar,render,redirect,terminateSession;
	import vibenotes.broadcast:WebSocketBroadcastService;

	this() 
	{
		m_broadcastService = new WebSocketBroadcastService();
	}

	private WebSocketBroadcastService m_broadcastService;

	private struct user {
		string username;
		bool loggedIn;
	}

	SessionVar!(user,"user") s_user;



	@path("/")
	void getIndex() 
	{
		redirect("home");
	} 

	void getHome()
	{
			auto channels = m_broadcastService.channels;
			render!("home.dt",channels);
	}
	void postHome(string name) {
		redirect("/n/"~name);
	}

	@path("/n/:name")
	void getEditor(string _name)
	{
		auto name = _name;
		render!("editor.dt",name);
	} 
	
	void getLogin(string error = null)
	{
		if(s_user.loggedIn) {
			terminateSession;
		}
		render!("login.dt",error);
	}

	void postLogin(string username, string password) 
	{	
		enforceHTTP(username.length > 0, HTTPStatus.forbidden,
				"User name must not be empty.");
		//enforceHTTP(checkpassword(username,password), HTTPStatus.forbidden,
			//"Invalid password.");
	
		s_user.username = username;
		s_user.loggedIn = true;
	
		redirect("/");
	}

	@path("/n/:channel/ws")
	void getChannelWS(HTTPServerRequest req, HTTPServerResponse res, string _channel) {
		return handleWebSockets(m_broadcastService.getChannelHandler(_channel))(req,res);
	}
}
