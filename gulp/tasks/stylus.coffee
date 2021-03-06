"use strict"
notifier = require "node-notifier"

module.exports = (gulp, $, config) ->

	gulp.task "stylus", ->

		gulp.src config.paths.client.css.entry + config.names.css.source
		.pipe $.plumber()
		.pipe $.if config.env is "dev", $.sourcemaps.init()
		.pipe $.stylus()
		.on "error", (err) ->
			notifier.notify
				message: "Error: " + err.message
			$.util.log $.util.colors.red err.message
		.pipe $.autoprefixer "last 2 versions", "> 1%"
		.pipe $.rename config.names.css.compiled
		.pipe $.header "/* " + config.names.project + " : " + config.version + " : " + new Date() + " */\n\n"
		.pipe $.size
			showFiles: true
		.pipe $.if config.env is "dev", $.sourcemaps.write "./"
		.pipe gulp.dest config.paths.client.css.dest

		gulp.src config.paths.client.css.entry + "**/*.styl"
		.pipe $.plumber()
		.pipe $.dss
			output: "index.html"
			templatePath: config.paths.client.css.entry + "styleguide"
		.pipe gulp.dest config.paths.client.css.dest