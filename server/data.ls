require "isf"
io = require "socket.io"
mongoose = require "mongoose"
Utils = require "../src/classes/helpers/EncodingUtils"

user-data-save-schema = mongoose.Schema {
	'host': String
	'ip': String
	'click-data': Object
	'hover-data': Object
	'scroll-data': Object
	'move-data': Object
}

user-data-save-schema.methods.decode-data = (data) ->
	data = Utils.decode-data data
	@normalize \hover, data.hover
	@normalize \click, data.click
	@normalize \scroll, data.scroll
	@normalize \move, data.move

user-data-save-schema.methods.normalize = (what, data) ->
	for key, value of data
		@["#{what}-data"] ?= {}; init = @["#{what}-data"][key]
		unless init then init = 0
		@["#{what}-data"][key] = parseInt(init) + parseInt(value) 


user-data-save-schema.methods.encode-data = -> Utils.encode-data hover: @["hover-data"], click: @["click-data"], scroll: @["scroll-data"], move: @['move-data']


class DataServer extends IS.Object
	(@app, @compiler, @server) ~>
		mongoose.connect "mongodb://localhost/itrackr"
		@data-server = io.listen @server
		@UserData = mongoose.model "datadump", user-data-save-schema
		@data-server.sockets.on "connection" (sock) ~>
			count = 0
			sock.on 'begin', ~>
				sock.host = it.host
				@UserData.find {"host": it.host, "ip": sock.handshake.address.address}, (err, data) ~>
					if err or data.length is 0 then sock.model = new @UserData host: it.host, ip: sock.handshake.address.address
					else sock.model = data[0]
			sock.on 'sendData', ~>
				unless not sock.model
					data = Utils.decode-data it
					sock.model.normalize \hover, data.hover
					sock.model.normalize \click, data.click
					sock.model.normalize \scroll, data.scroll
					sock.model.normalize \move, data.move
					count += 1
					if count is 3 
						console.log "Saving Now"
						sock.model.save!
						count := 0
			sock.on 'requestData', (ip) ~>
				if ip isnt 'aggregated'
					@UserData.find {host: sock.host, ip: sock.model.ip}, (err, data) ~>
						if err or data.length is 0 then msg = "404"
						else msg = data[0].encode-data!
						sock.emit "receiveData", data: msg
				else 
					final = new @UserData {host: sock.host}
					@UserData.find {host: sock.host}, (err, data) ~>
						if err or data.length is 0 then msg = "404"
						else 
							for item in data then let i = item
								[\click \scroll \move \hover].map ~>
									final["#{it}-data"] ?= {}; i["#{it}-data"] ?= {}
									final["#{it}-data"] = @join final["#{it}-data"], i["#{it}-data"]
							msg = final.encode-data!
						sock.emit "receiveData", data:msg
			sock.on "requestIPs", ~>
				@UserData.find {host: sock.host}, (err, data) ~>
					if err or data.length is 0 then msg = "404"
					else
						ips = []
						for item in data
							ips.push item.ip
						sock.emit "receiveIPs", ips

			sock.on "disconnect", ~>
				if sock.model then sock.model.save!
	join: (a, b) ~>
		for key, value of a
			if b[key]? then b[a] += value
			else b[a] = value
		b


module.exports = DataServer