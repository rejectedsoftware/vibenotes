module vibenotes.broadcast;

import vibe.core.concurrency : send, receiveOnly;
import vibe.core.core: Task, rawYield, runTask;
import vibe.core.log: logInfo;
import vibe.core.sync: TaskCondition, TaskMutex;
import vibe.http.websockets;


class WebSocketBroadcastService {
	private struct SocketInfo {
		Task tid;
		string channel;
	}

	private {
		TaskCondition m_signal;
		SocketInfo[void*] m_sockets;
	}

	this() {
		m_signal = new TaskCondition(new TaskMutex);
	}

	auto getChannelHandler(string channel)
	{
		void callback (scope WebSocket socket) {
			auto sockid = cast(void*)socket;

			auto sendtask = runTask({
				while(socket.connected) {
					auto message = receiveOnly!string();
					socket.send(message);
				}
			});

			m_sockets[sockid] = SocketInfo(sendtask, channel);
			scope (exit) m_sockets.remove(sockid);

			while (socket.waitForData()) {
				auto data = socket.receiveText();
				auto qs = m_sockets.dup;
				foreach (sid, si; qs) {
					if (!si.tid.running || sid == sockid) continue;
					if (si.channel == channel)
						si.tid.send(cast(string)data);
				}
			}
		}

		return &callback;
	}

	@property string[] channels()
	const {
		int[string] chann;
		foreach (si; m_sockets)
			if (si.channel !in chann)
				chann[si.channel] = 1;
		return chann.keys;
	}		
}
