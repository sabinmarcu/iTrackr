class MenuController extends IS.Object
	~> 
		@log "Menu Controller Created"
		@placeholder = document.createElement "div"
		@placeholder.innerHTML = DepMan.render "menu"
		document.body.appendChild @placeholder
		$ 'body' .addClass "itmenuactive"
		[\click \hover \move].map ~> 
			$ "##{it}-heat" .click (e) ~>
				@log "Should start #{it}-heat"
				@release-heatmap!
				@heatmap = new (DepMan.renderer "HeatMap")(it)
		$ '#combined-heat' .click ~>
			@release-heatmap!
			@heatmap = new (DepMan.renderer "HeatMapCombined")(it)
		$ '#remove-heat' .click ~> @release-heatmap!
		@scroll-average = $ '#scroll-average span'
		DepMan.helper "EncodingUtils"
		DepMan.helper "DataTransfer"
		@grid = new (DepMan.model "grid")
		@init-transfers!
	release-heatmap: ~>
		if @heatmap 
			@heatmap.destroy!
			delete @heatmap
	init-transfers: ~>
		@interval = setInterval @query, 1000
		iTTransfer.socket.on "receiveData", @transfer
	query: ~> iTTransfer.socket.emit "requestData"
	transfer: ~>
		unless it.data is "404"
			data = Utils.decode-data it.data
			if @heatmap then @heatmap.sequence data
			sortable = []
			for key, value of data.scroll
				key = key.split ","
				sortable.push [key[0], key[1], value]
			sortable.sort (a, b) -> b[2] - a[2]
			@scroll-average.html parseInt ((@grid.untranslate-scroll sortable[0]).x / document.body.scrollHeight * 100 )
	destroy: ~>
		document.body.removeChild @placeholder
		$ 'body' .removeClass 'itmenuactive'
		@release-heatmap!
		clearInterval @interval
		iTTransfer.socket.removeAllListeners "receiveData"
		@grid.destroy!; delete @grid

module.exports = MenuController