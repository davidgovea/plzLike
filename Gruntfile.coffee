module.exports = (grunt) ->
	grunt.initConfig
		
		# Import package manifest
		pkg: grunt.file.readJSON("jquery.json")
		
		# Banner definitions
		meta:
			banner: """
			/*
			  *  <%= pkg.title || pkg.name %> - v<%= pkg.version %>
			  *  <%= pkg.description %>
			  *  <%= pkg.homepage %>
			  *
			  *  Made by <%= pkg.author.name %>
			  *  <%= pkg.licenses[0].type %> License
			*/
			"""
		
		# Concat definitions
		concat:
			dist:
				src: ["src/jquery.plzlike.js"]
				dest: "dist/jquery.plzlike.js"

			options:
				banner: "<%= meta.banner %>"

		
		# Lint definitions
		jshint:
			files: ["src/jquery.plzlike.js"]
			options:
				jshintrc: ".jshintrc"

		
		# Minify definitions
		uglify:
			my_target:
				src: ["dist/jquery.plzlike.js"]
				dest: "dist/jquery.plzlike.min.js"

			options:
				banner: "<%= meta.banner %>"

		# Compile Stylus->CSS
		stylus:
			compile:
				files:
					"dist/jquery.plzlike.css": "src/jquery.plzlike.styl"

		# Minify styles
		cssmin:
			main:
				files:
					"dist/jquery.plzlike.min.css": "dist/jquery.plzlike.css"
		
		# Coffeescript compilation
		coffee:
			compile:
				files:
					"dist/jquery.plzlike.js": "src/jquery.plzlike.coffee"

	grunt.loadNpmTasks "grunt-contrib-concat"
	grunt.loadNpmTasks "grunt-contrib-stylus"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.registerTask "default", ["coffee", "stylus", "uglify", "cssmin"]
	grunt.registerTask "travis", ["jshint"]