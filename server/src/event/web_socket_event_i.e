note
	description: "[
		API to perform actions like opening and closing the connection, sending and receiving messages, and listening
		for events.
	]"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	WEB_SOCKET_EVENT_I

inherit

	WEB_SOCKET_CONSTANTS

	REFACTORING_HELPER

feature -- Web Socket Interface

	on_event (conn: WS_STREAM_SOCKET; a_message: STRING; a_opcode: INTEGER)
			-- Called when a frame from the client has been receive
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		local
			l_message: STRING
		do
			create l_message.make_empty
			if a_opcode = Binary_frame then
				do_send (conn, Binary_frame, a_message)
			elseif a_opcode = Text_frame then
				do_send (conn, Text_frame, a_message)
			elseif a_opcode = Pong_frame then
					-- log ("Its a pong frame")
					-- at first we ignore  pong
					-- FIXME: provide better explanation
			elseif a_opcode = Ping_frame then
				do_send (conn, Pong_frame, a_message)
			elseif a_opcode = Connection_close_frame then
				conn.send_message (close_message) -- Send close
			end
		end

	on_open (conn: WS_STREAM_SOCKET)
			-- Called after handshake, indicates that a complete WebSocket connection has been established.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		deferred
		end

	on_close (conn: WS_STREAM_SOCKET)
			-- Called after the WebSocket connection is closed.
		require
			conn_attached: conn /= Void
			conn_valid: conn.is_open_read and then conn.is_open_write
		do
			conn.send_message (close_message)
		end

	close_message: STRING
		do
			create Result.make_empty
			Result.append_code (129)
			Result.append_code (2)
		end

feature {NONE} -- Implementation

	do_send (conn: WS_STREAM_SOCKET; a_opcode:INTEGER; a_message: STRING)
		local
			l_chunks: INTEGER
			i: INTEGER
			l_index: INTEGER
			l_chunk_size: INTEGER
			l_header_message: STRING
			l_message_count: INTEGER
		do
			create l_header_message.make_empty
			l_header_message.append_code ((0x80 | a_opcode).to_natural_32)
			l_message_count := a_message.count
			if l_message_count >= 0xffff then
					--! Improve. this code needs to be checked.
				l_header_message.append_code ((0 | 127).to_natural_32)
				l_header_message.append_character ('%U') -- %U -> code 0
				l_header_message.append_character ('%U')
				l_header_message.append_character ('%U')
				l_header_message.append_character ('%U')
				l_header_message.append_character ((l_message_count |>> 32).to_character_8)
				l_header_message.append_character ((l_message_count |>> 16).to_character_8)
				l_header_message.append_character ((l_message_count |>> 8).to_character_8)
				l_header_message.append_character (l_message_count.to_character_8)
			elseif l_message_count > 125 then
				l_header_message.append_code ((0 | 126).to_natural_32)
				l_header_message.append_code ((l_message_count |>> 8).as_natural_32)
				l_header_message.append_character (l_message_count.to_character_8)
			else
				l_header_message.append_code (l_message_count.as_natural_32)
			end
			l_header_message.append (a_message)
			conn.put_string (l_header_message)
--			l_chunk_size := 16384
--			if a_message.count < l_chunk_size then
--				print ("%NSend Message:"+a_message)
--				conn.put_string (a_message)
--			else
--				l_chunks := a_message.count // l_chunk_size
--				from
--					i := 1
--					l_index := 1
--				until
--					i > l_chunks + 1
--				loop
----					if conn.ready_for_writing and then i <= l_chunks then
--						conn.put_string (a_message.substring (l_index, l_chunk_size * i))
--						l_index := l_chunk_size * i + 1
--						i := i + 1
----					else
----						if l_index < a_message.count then
----							conn.put_string (a_message.substring (l_index, a_message.count))
----						end
----						i := i + 1
----					end
--				end
--			end
		end



end
