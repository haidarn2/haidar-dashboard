require 'net/https'
require 'json'
require 'uri'
require 'crack'


north_stop_id = "8475"
south_stop_id = "8490"
east_stop_id = "6371"
west_stop_id = "9940"


=begin
SCHEDULER.every '2m', :first_in => 0 do |job|
  uri = URI.parse(predictions_url)
  xml_response = Net::HTTP.get_response(uri).body
  json_response = JSON.parse(Crack::XML.parse(xml_response).to_json)
  body = json_response["body"]
  predictions = body["predictions"]
  #send_event('ttc', predictions)
  #send_event('ttc', predictions)
end
=end

SCHEDULER.every '2s', :first_in => 0 do |job|
  #send_event('nextbus_north', generate_payload(north_stop_id))
  #send_event('nextbus_south', generate_payload(south_stop_id))
  #send_event('nextbus_east', generate_payload(east_stop_id))
  #send_event('nextbus_west', generate_payload(west_stop_id))
end

def generate_payload(stop_id)
  agency_id = "ttc"
  api_url = "http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=#{agency_id}&stopId=#{stop_id}"
  raw_data = doFetch(api_url)
  code, times = doParse(raw_data)
  times_str = code + times.map { |time| "#{time}m"}.join(', ') 
  {"nextBus":"#{times[0]}m", "routeOne":times_str, "routeTwo":"", "routeThree":""}
end

def doFetch(url)
  uri = URI.parse(url)
  xml_response = Net::HTTP.get_response(uri).body
  json_response = JSON.parse(Crack::XML.parse(xml_response).to_json)
  json_response["body"]
end

def doParse(data)
  #return "24E: ", [3, 4, 5, 6]
  {"24E: " => [3,4,5,6]}
  #{"code" => "24E: ", "times" => [3, 4, 5, 6]}
  #{"code":"24E: ", "times":[3, 4, 5, 7]}
end