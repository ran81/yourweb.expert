"use strict"

config = require "../../config/environment"
request = require "request"

exports.index = (req, res) ->

	request "http://api.worldweatheronline.com/free/v1/weather.ashx?q=Kunming&format=json&num_of_days=1&key=" + config.weatheronline.clientID, (error, response, body) ->
		if !error and response.statusCode is 200 and !body.data
			allWeather = JSON.parse body
			if allWeather.data.current_condition
				weather =
					condition: allWeather.data.current_condition[0].weatherCode
					temperature: allWeather.data.current_condition[0].temp_C
				res.jsonp weather
			else res.status 500