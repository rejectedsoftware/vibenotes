module vibenotes.broadcast;

import vibe.core.log;
import vibe.http.server;
import vibe.http.websockets;
import vibe.core.signal;

class WebSocketBroadcastService {
	private {
		Signal m_signal;
		string[][WebSocket] m_queues;
		string[WebSocket] m_channels;
	}

	this() {
		m_signal = new Signal();
	}

	void handleRequest(HttpServerRequest req, HttpServerResponse res) {
		auto pv = "channel" in req.params;
		auto channel = pv ? *pv : "default";

		logInfo("Channel: %s", channel);
		auto callback = handleWebSockets( (socket) {
			m_queues[socket] = [];
			m_channels[socket] = channel;
			m_signal.registerSelf();
			while( socket.connected ) {
				if( socket.dataAvailableForRead() ) {
					auto data = socket.receive();
					foreach( s, ref q ; m_queues ) {
						auto pc = s in m_channels;
						if( s !is socket && pc && *pc == channel ) q ~= cast(string)data;
					}
					m_signal.emit();
				}

				foreach( message ; m_queues[socket] ) {
					socket.send(cast(ubyte[])message);
				}
				m_queues[socket] = [];
				yield();
			}
			m_signal.unregisterSelf();
			m_queues.remove(socket);
		});

		callback(req, res);
	}
}