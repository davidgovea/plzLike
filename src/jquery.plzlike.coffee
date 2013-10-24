do ($ = jQuery, window, document) ->

	pluginName = "plzLike"
	defaults =
		appId: ''
		page: ''
		fbScope: 'user_likes,email'

		width: null
		height: null

		firebaseUrl: ''
		firebaseNs: "plzlike-entrants"

		webhookUrl: ''
		method: 'POST'

	class PlzLike
		constructor: (@element, options) ->
			@settings = $.extend {}, defaults, options
			@_defaults = defaults
			@_name = pluginName
			@init()

		init: ->
			# Add container class for stylage
			$(@element).addClass('plzlike-container')

			# Show the "loading" template
			@changeView('loading')

			# Async load of facebook SDK
			@loadFB =>
				# Grab page ID from nick/url
				@fetchPageId =>
					# Ready to begin - show begin template
					@changeView('begin')

				# Subscribe to facebook auth chnges
				@fbAuthSubscribe()
				# Bind delegated click handlers
				@initClickHandlers()

			if @settings.firebaseUrl
				# Fire up a firebase if url provided
				@firebase = new Firebase(@settings.firebaseUrl)

		# Loads Facebooks JS SDK (if not already present)
		loadFB: (done) ->
			if window.FB?
				setTimeout(done, 0)
			else
				$.getScript '//connect.facebook.net/en_UK/all.js', =>
					FB.init
						appId: @settings.appId
						status: false
						xfbml: false
						# channelUrl: ''
					done()

		# Fetches facebook page ID from page nickname
		fetchPageId: (done) ->
			FB.api "/#{@settings.page}", (res) =>
				@settings.pageId = res.id
				done()

		# Listen to facebook auth changes
		fbAuthSubscribe: ->
			FB.Event.subscribe 'auth.authResponseChange', (res) =>
				if res.status is 'connected'
					this.userId = res.authResponse?.userID

					FB.api "/me/likes/#{@settings.pageId}", (likeData) =>
						if likeData.data?.length
							# They aleady like us!!!
							@changeView('liked')

						else
							# Give 'em the like box!
							@changeView('like')
							# Listen for a like
							FB.Event.subscribe 'edge.create', (href, widget) =>
								debugger
								# Is it us?
								if href.match new RegExp(@settings.page, 'i')
									@changeView('liked')

				else
					alert "You must connect with our app to enter"

		# Delegated click handlers for begin/submit buttons
		initClickHandlers: ->
			$el = $(@element)

			$el.on 'click', '.plzlike-begin button', (evt) =>
				evt.preventDefault()
				evt.stopPropagation()
				# Call FB SDK Login
				FB.login ((res)->), scope: @settings.fbScope

			$el.on 'click', '.plzlike-liked button', (evt) =>
				evt.preventDefault()
				evt.stopPropagation()
				@submit()

		# They liked you! Submit FB user data to Firebase or Webhook
		submit: ->
			complete = (err) ->
				@changeView('done')
				debugger

			# Get available data about this FB user
			FB.api '/me', (userData) =>
				if @firebase
					submitFn = @_submitFirebase
				else if @settings.webhookUrl
					submitFn = @_submitPost
				else
					throw new Error "No data store configured"
				# DO IT
				submitFn userData, complete

		# Submits data to Firebase.io cloud datastore
		_submitFirebase: (data, done) =>
			# Get user record firebase reference
			userRecord = @firebase.child("#{@settings.firebaseNs}/#{@userId}")

			# Check for existing
			firstReceipt = true
			userRecord.on 'value', (snapshot) =>
				if snapshot?.val() and firstReceipt
					# They've already entered!
					@changeView('dupe')
				else
					# First time. Set the data.
					userRecord.set(data, done)

				firstReceipt = false

		# POSTs user data to URL
		_submitPost: (data, done) =>
			$.ajax
				url: @settings.webhookUrl
				method: @settings.method
				data: data
				success: (res) =>
					# Already entered - got HTTP 409/420/429
					if res.code in [409, 420, 429]
						@changeView('dupe')
					# A-OK
					else done()
				error: (jqXHR, code, text) -> done new Error(text)

		# Switches the visible/active view
		changeView: (name) =>
			$el = $(@element)

			# Yield to existing elements
			existing = $el.find(".plzlike-#{name}")

			if existing.length
				# We good!
				$incoming = existing
			else
				# Or create new elements from basic templates
				$incoming = $ "<div class='plzlike-#{name}'>#{@templates[name].call(this)}</div>"
				# ..and append it to the container
				$el.append $incoming

			# Deactivate old view
			$el.find('.plzlike-active').removeClass('plzlike-active')

			# Parse any Facebook widgets (like/send/etc)
			FB?.XFBML.parse($incoming.get(0))

			# Ignition! (activate new view)
			setTimeout (-> $incoming.addClass('plzlike-active')), 0

		templates:
			# Loading - shown before FB SDK loaded
			loading: -> """
				LOADING...
			"""
			# Begin - start button to bring up login/permissions
			begin: ->
				return """
					<button>Get started</button>
				"""
			# Like us! Show FB likebox
			like: ->
				return """
					<div class="fb-like-box"
						data-href="http://www.facebook.com/#{@settings.pageId}"
						data-width="#{@settings.width ? $(@element).width()}"
						data-height="#{@settings.height ? $(@element).height() or ''}"
						data-colorscheme="light"
						data-show-faces="true"
						data-header="false"
						data-stream="false"
						data-show-border="false">
					</div>
				"""
			# You liked us, thanks! Show submit button
			liked: => """
				<button>Submit entry</button>
				<div class="disclaimer">
					<small>This promotion is in no way sponsored, endorsed, administered by, or associated with Facebook.</small>
				</div>
			"""
			# All done! Thanks.
			done: -> """
				Thanks for entering! Why not share?
				<div class="fb-send"
					data-href="#{window.location.href}"
					data-colorscheme='light'>
				</div>
			"""
			# They've already entered
			dupe: -> """
				Already entered
			"""

	# A really lightweight plugin wrapper around the constructor,
	# preventing against multiple instantiations
	$.fn[pluginName] = (options) ->
		@each ->
			if !$.data(@, "plugin_#{pluginName}")
				$.data(@, "plugin_#{pluginName}", new PlzLike(@, options))
