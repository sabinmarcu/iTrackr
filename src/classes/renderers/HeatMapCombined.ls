class HeatMapCombined extends DepMan.renderer "HeatMap"
	~> super "joined"
	get-sets: ~>
		sets = @join it.move, it.click
		sets = @join sets, it.hover
		super joined: sets
		sets = @passthrough sets, it.scroll
		sets

	join: (a, b) ~>
		for key, value of a
			if b[key] then b[key] += a[key]
			else b[key] = a[key]
		b

	passthrough: (sets, scrolls) ~>

module.exports = HeatMapCombined
