module vibenotes.vibenotes;

import vibenotes.broadcast : WebSocketBroadcastService;

import vibe.http.server : HTTPServerResponse, HTTPServerRequest, HTTPStatus, enforceHTTP;
import vibe.http.websockets : handleWebSockets;
import vibe.web.common: contentType, path;
import vibe.web.web : SessionVar, render, redirect, terminateSession;


class VibeNotesWeb {
	private struct LoginData {
		string username;
		bool loggedIn;
	}

	private {
		SessionVar!(LoginData,"user") s_loginData;
		WebSocketBroadcastService m_broadcastService;
	}

	this() 
	{
		m_broadcastService = new WebSocketBroadcastService();
	}

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

	void postHome(string name)
	{
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
		if (s_loginData.loggedIn) terminateSession();
		render!("login.dt",error);
	}

	void postLogin(string username, string password) 
	{	
		enforceHTTP(username.length > 0, HTTPStatus.forbidden,
				"User name must not be empty.");
		//enforceHTTP(checkpassword(username,password), HTTPStatus.forbidden,
			//"Invalid username or password.");
	
		s_loginData = LoginData(username, true);
	
		redirect("/");
	}

	@path("/n/:channel/ws")
	void getChannelWS(HTTPServerRequest req, HTTPServerResponse res, string _channel)
	{
		return handleWebSockets(m_broadcastService.getChannelHandler(_channel))(req,res);
	}
}
