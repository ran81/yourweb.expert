api = require "../api/api.coffee"

###*
 * This class controls the Blog component, retrieving,
 * populating, and displaying a list of articles. If
 * there are no blog articles to display, the component
 * is removed from the DOM.
###
class Blog

	constructor: ->

		@el =
			component: document.querySelector ".js-blog"
			list: document.querySelector ".js-blog-list"
			navigation: document.querySelector ".js-navigation-menu"

		# Only try and get the articles if the component
		if @el.component and @el.list

			@getArticles()

	###*
	 * Add analytics tracking for blog post links.
	###
	addEventListeners: ->

		links = document.querySelectorAll ".o-blog-post-list__item__link"

		for link in links

			link.addEventListener "click", (e) ->

				ga "send", "event", "blog post", "click", "navigate to", e.target,
					nonInteraction: 1

	###*
	 * Format the date so it can be displayed
	 * alongside the blog title, i.e.
	 * 25th Dec
	 * @param  {String}     Date The date to be formatted
	 * @return {String}     An HTML string containing the formatted date
	###
	formatDate: (date) ->

		date = new Date date
		day = date.getDate()
		day = day + "<sup>" + @getOrdinal(day) + "</sup>"
		month = @getMonth date.getMonth()

		formatedDate = day + " " + month

	###*
	 * Query the API to retrieve the blog articles. I'm
	 * not worried about having the most up to date
	 * articles on here and would rather save a request if I
	 * can so I'll first check if we have articles saved from
	 * a previous visit in the past week, otherwise we'll
	 * fetch from the server.
	###
	getArticles: ->

		makeRequest = =>

			url = api.getURL "blog"

			fetch url
			.then (response)->

				response.json()

			.then (data) =>

				@handleSuccess data

			.catch (reason) =>

				@handleFailure()

		# localStorage.setItem('testObject', JSON.stringify(testObject));
		data = JSON.parse localStorage.getItem "articles"

		ONE_WEEK = 60 * 60 * 24 * 7 * 1000

		if data isnt null

			if ((new Date()) - (new Date(data.date))) < ONE_WEEK

				# Wait for the navigation menu items
				# to be added by the navigation component
				setTimeout =>
					@handleSuccess data.articles
				, 1000

			else

				makeRequest()

		else

			makeRequest()

	###*
	 * Create a list item DOM node for a blog
	 * item.
	 * @param  {Object} article A JSON object containing the article data
	 * @return {Object}         A DOM node for the list item
	###
	getListItem: (article) ->

		item = document.createElement "li"
		item.classList.add "o-blog-post-list__item"

		link = document.createElement "a"
		link.classList.add "o-blog-post-list__item__link"
		link.href = article.link
		link.title = "Read more"

		heading = document.createElement "h2"
		heading.classList.add "o-blog-post-list__item__heading"
		heading.textContent = article.title

		date = document.createElement "div"
		date.classList.add "o-blog-post-list__item__date"
		date.innerHTML = @formatDate article.published

		link.appendChild heading
		link.appendChild date

		item.appendChild link

		item

	###*
	 * Find a navigation menu item that links to
	 * the blog component.
	 * @return {Object} The DOM node for the navigation item
	###
	getMenuItem: ->

		link = @el.navigation.querySelector "[href='#" + @el.component.id + "']"
		if link then menuItem = link.parentNode

	###*
	 * Get the short name of a month.
	 * @param  {Integer} month The number of the month (0-11)
	 * @return {String}        The short name of the month
	###
	getMonth: (month) ->

		monthNames = [
			"Jan"
			"Feb"
			"Mar"
			"Apr"
			"May"
			"Jun"
			"Jul"
			"Aug"
			"Sep"
			"Oct"
			"Nov"
			"Dec"
		]

		monthNames[month]

	###*
	 * Get the ordinal (e.g. th, nd, st, rd) for
	 * any particular date.
	 * @param  {Integer} day A date value
	 * @return {String}      The ordinal
	###
	getOrdinal: (day) ->

		if day > 20 or day < 10

			switch day % 10
				when 1 then return "st"
				when 2 then return "nd"
				when 3 then return "rd"

		"th"

	###*
	 * What to do if blog articles cannot be retrieved?
	 * Remove the blog component and the corresponding
	 * navigation menu item.
	###
	handleFailure: ->

		# Remove the component if articles can't be retrieved
		@el.component.parentNode.removeChild @el.component

		# Also remove the navigation item if necessary
		if @el.navigation
			menuItem = @getMenuItem()
			if menuItem then menuItem.parentNode.removeChild menuItem

		# Trigger resize to update the navigation scroll
		# spy functionality so that we're not watching
		# for when we scroll to the blog section
		window.dispatchEvent new CustomEvent "resize"

	###*
	 * What to do when we can retrieve blog articles?
	 * Generate the list of articles and display the
	 * component and its navigation menu item.
	 * @param  {Object} data A JSON object containing all data for all articles
	###
	handleSuccess: (data) ->

		# Save to local storage
		dataToSave =
			date: new Date()
			articles: data
		localStorage.setItem "articles", JSON.stringify dataToSave

		# Generate the list
		@populateList data

		# Display the blog component
		@el.component.classList.add "is-loaded"

		# Show the navigation item for the blog component
		menuItem = @getMenuItem()
		if menuItem then menuItem.classList.remove "is-hidden"

	###*
	 * Generate a list of blog articles.
	 * @param  {Object} articles A JSON object containing all the articles data
	###
	populateList: (articles) ->

		# Only use the 5 latest articles
		articles = articles.slice 0, 5

		# Empty the list of any existing content
		@el.list.innerHTML = ""

		# Generate a list item for each article and
		# append to the list
		for article in articles

			@el.list.appendChild @getListItem article

		@addEventListeners()


module.exports = new Blog