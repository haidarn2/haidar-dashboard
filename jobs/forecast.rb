require 'net/https'
require 'json'
require 'uri'

# Forecast API Key from https://developer.forecast.io
forecast_api_key = "ea35c1e70e2e528940f8370ba176a261"

# Latitude, Longitude for location
forecast_location_lat = "43.741208"
forecast_location_long = "-79.311698"

# Unit Format
# "us" - U.S. Imperial
# "si" - International System of Units
# "uk" - SI w. windSpeed in mph
# "auto" - auto based on region
forecast_units = "auto"

=begin  
SCHEDULER.every '1.5m', :first_in => 0 do |job|
  uri = URI.parse("https://api.darksky.net/forecast/#{forecast_api_key}/#{forecast_location_lat},#{forecast_location_long}?units=#{forecast_units}")
  response = Net::HTTP.get_response(uri)
  forecast = JSON.parse(response.body)  
  forecast_current_temp = forecast["currently"]["temperature"].round
  forecast_hour_summary = forecast["minutely"]["summary"]
  send_event('forecast', { temperature: "#{forecast_current_temp}&deg;", hour: "#{forecast_hour_summary}"})
end
=end

SCHEDULER.every '1.5m', :first_in => 0 do |job|
  #uri = URI.parse("https://api.darksky.net/forecast/#{forecast_api_key}/#{forecast_location_lat},#{forecast_location_long}?units=#{forecast_units}")
  #response = Net::HTTP.get_response(uri)
  #forecast = JSON.parse(response.body)  
  forecast_current_temp = "69"
  forecast_hour_summary = "lol kappa pride"
  send_event('forecast', { temperature: "#{forecast_current_temp}&deg;", hour: "#{forecast_hour_summary}"})
end