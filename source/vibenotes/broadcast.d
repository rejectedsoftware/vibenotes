module vibenotes.broadcast;


class WebSocketBroadcastService {
	import vibe.core.core:rawYield;
	import vibe.core.log:logInfo;
	import vibe.core.sync:TaskCondition,TaskMutex;
	import vibe.http.websockets;

	private {
		TaskCondition m_signal;
		string[][WebSocket] m_queues;
		string[WebSocket] m_channels;
	}

	this() {
		m_signal = new TaskCondition(new TaskMutex);
	}

	auto getChannelHandler(string channel) {
	
		logInfo("Channel: %s", channel);
		void callback (scope WebSocket socket) { 
			m_queues[socket] = [];
			m_channels[socket] = channel;
			m_signal.mutex.lock;
			while( socket.connected ) {
				if (socket.dataAvailableForRead()) { // here is some fatal error with the connection stream
					auto data = socket.receiveText();
					foreach( s, ref q ; m_queues ) {
						auto pc = s in m_channels;
						if( s !is socket && pc && *pc == channel ) q ~= cast(string)data;
					}
					m_signal.notifyAll();
				}

				foreach( message ; m_queues[socket] ) {
					socket.send(cast(ubyte[])message);
				}
				m_queues[socket] = [];
				rawYield();
			}
			m_signal.mutex.unlock;
			m_queues.remove(socket);
		}

		return &callback;
	}

	@property string[] channels() const {
		int[string] chann;
		foreach(WebSocket k, v; m_channels)
			if( !(v in chann) )
				chann[v] = 1;
		return chann.keys;
	}		
}
