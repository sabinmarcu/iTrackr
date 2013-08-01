class DataTransfer extends IS.Object
	(cb) ~> 
		script = document.create-element "script"
		script.src = "http://localhost:80/socket.io/socket.io.js"
		script.onload = ~>
			@socket = io.connect "http://localhost:80/"
			@socket.emit "begin", host: window.location.toString!substr 7
			cb?!
		@log script
		document.body.append-child script

	send: ~>
		@socket?.emit "sendData", it

module.exports = DataTransfer