class HeatMapRenderer extends DepMan.renderer "Base"
	(@prop) ~>
		super!
		@log "Heatmap Created" 
		@buffer.id = "heatmap-canvas"
		@grid = new (DepMan.model "grid")
		@resize!; window.addEventListener "resize", @resize
		document.body.appendChild @buffer
	destroy: ~>
		window.removeEventListener "resize", @resize
		@grid.destroy!; delete @grid
		@log @buffer
		document.body.removeChild @buffer; delete @buffer
	resize: ~>
		@buffer.width = document.body.scrollWidth
		@buffer.height = document.body.scrollHeight
	sequence: ~>
		@reset!
		sortable = @get-sets it
		@color = r: 256, g: 0, b: 0
		for set in sortable
			index = @grid.untranslate-point set[0]
			alpha-delta = @color.r / 256 + @color.g / 256 + @color.b / 256
			@context.fill-style = "rgba(#{@color.r}, #{@color.g}, #{@color.b}, #{alpha-delta})"
			@context.fill-rect index.x, index.y, 50, 50
			if @color.r 
				@color.r -= 30
				if @color.r <= 0 then @color.r = 0; @color.g = 256
			else 
				if @color.g 
					@color.g -= 30
					if @color.g <= 0 then @color.g = 0; @color.b = 256
				else @color.b -= 30

	get-sets: ->
		sortable = []
		for key, value of it[@prop]
			sortable.push [key, value]
		sortable.sort (a, b) -> b[1] - a[1]
		sortable



module.exports = HeatMapRenderer