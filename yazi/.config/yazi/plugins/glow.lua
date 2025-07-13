return {
	run = function(ctx)
		ctx.shell(string.format("glow --width=%d %s", ctx.area.w, ctx.file.path:escape()), {
			block = true,
			orphan = false,
		})
	end,
}
