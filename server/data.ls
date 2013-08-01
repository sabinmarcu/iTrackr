require "isf"
io = require "socket.io"
mongoose = require "mongoose"
Utils = require "../src/classes/helpers/EncodingUtils"

user-data-save-schema = mongoose.Schema {
	'host': String
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
		@models = {}
		@data-server.sockets.on "connection" (sock) ~>
			count = 0
			sock.on 'begin', ~>
				sock.host = it.host
				if @models[sock.host] 
					@models[sock.host].users ?= 0
					@models[sock.host].users += 1
				else
					@UserData.find {"host": it.host}, (err, data) ~>
						if err or data.length is 0 then @models[sock.host] = new @UserData host: it.host
						else @models[sock.host] = data[0]
			sock.on 'sendData', ~>
				data = Utils.decode-data it
				@models[sock.host].normalize \hover, data.hover
				@models[sock.host].normalize \click, data.click
				@models[sock.host].normalize \scroll, data.scroll
				@models[sock.host].normalize \move, data.move
				count += 1
				if count is 3 
					console.log "Saving Now"
					@models[sock.host].save!
					count := 0
			sock.on 'requestData', ~>
				if @models[sock.host] then sock.emit "receiveData", data: @models[sock.host].encode-data!
				else
					@UserData.find {host: sock.host}, (err, data) ~>
						if err or data.length is 0 then msg = "404"
						else msg = data[0].encode-data!
						sock.emit "receiveData", data: msg
			sock.on "disconnect", ~>
				if @models[sock.host] then
					@models[sock.host].save!; @models[sock.host].users -= 1
					if @models[sock.host].users is 0 then delete @models[sock.host]

module.exports = DataServer