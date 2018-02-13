require 'net/https'
require 'json'
require 'uri'
require 'crack'
require 'pp'


north_stop_id = "8475"
south_stop_id = "8478"
east_stop_id = "5328"
west_stop_id = "5326"

SCHEDULER.every '5s', :first_in => 0 do |job|
  send_event('nextbus_north', generate_payload(north_stop_id))
  send_event('nextbus_south', generate_payload(south_stop_id))
  send_event('nextbus_east', generate_payload(east_stop_id))
  send_event('nextbus_west', generate_payload(west_stop_id))
end

def generate_payload(stop_id)
  agency_id = "ttc"
  api_url = "http://webservices.nextbus.com/service/publicXMLFeed?command=predictions&a=#{agency_id}&stopId=#{stop_id}"
  #raw_data = ""
  raw_data = do_fetch(api_url)
  schedule = do_parse(raw_data)
  
  minTime = schedule.values.flatten.min
  nextBus = minTime > 0 ? "#{minTime}m" : "Due"
  routes = schedule.keys

  times_str_one = format_time_str(routes[0], schedule[routes[0]])
  times_str_two = format_time_str(routes[1], schedule[routes[1]])
  times_str_three = format_time_str(routes[2], schedule[routes[2]]) 
  
  {"nextBus":"#{nextBus}", "routeOne":times_str_one, "routeTwo":times_str_two, "routeThree":times_str_three}
end

def format_time_str(code, times)
  if (code.nil? || times.nil?)
    ""
  else
    code + ': ' + times.map { |time| time == 0 ? "Due" : "#{time}m"}.join(', ')
  end
end

def do_fetch(url)
  uri = URI.parse(url)
  xml_response = Net::HTTP.get_response(uri).body
  json_response = JSON.parse(Crack::XML.parse(xml_response).to_json)
  json_response["body"]
end

# format is a hashmap where key: bus route and value: is times
def do_parse(data)
  #data = {"predictions"=>[{"direction"=>{"prediction"=>[{"epochTime"=>"1518489808605", "seconds"=>"183", "minutes"=>"3", "isDeparture"=>"false", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7770", "block"=>"24_35_142", "tripTag"=>"35800914"}, {"epochTime"=>"1518490260213", "seconds"=>"635", "minutes"=>"10", "isDeparture"=>"false", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7750", "block"=>"24_6_60", "tripTag"=>"35800915"}, {"epochTime"=>"1518490643547", "seconds"=>"1018", "minutes"=>"16", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7795", "block"=>"24_7_70", "tripTag"=>"35800916"}, {"epochTime"=>"1518491063547", "seconds"=>"1438", "minutes"=>"23", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"8160", "block"=>"24_41_90", "tripTag"=>"35800917"}, {"epochTime"=>"1518491543547", "seconds"=>"1918", "minutes"=>"31", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7712", "block"=>"24_8_80", "tripTag"=>"35800918"}], "title"=>"North - 24a Victoria Park towards Steeles"}, "agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"24-Victoria Park", "routeTag"=>"24", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992"}, {"agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"324-Victoria Park Night Bus", "routeTag"=>"324", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992", "dirTitleBecauseNoPredictions"=>"North - 324 Victoria Park Blue Night towards Steeles via Sheppard and Warden"}], "copyright"=>"All data copyright Toronto Transit Commission 2018."}
  predictions = data['predictions']
  
  ret = Hash.new { |hash, key| hash[key] = [] }

  what = predictions.map { |route| route['direction'] }.compact.flatten
  
  what.each do |eh|
    eh['prediction'].each do |wtf|
      branch = wtf['branch']
      mins = Integer(wtf['minutes'])
      ret[branch] << mins
    end
  end

  ret
end