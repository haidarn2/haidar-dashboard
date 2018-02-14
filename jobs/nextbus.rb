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
  routes = schedule.keys.sort

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

def do_fetch(url, redirectLimit = 10)
  raise "HTTP redirect limit reached! url=#{url}" if redirectLimit == 0 
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  case response
  when Net::HTTPSuccess then 
    # success
    xml_response = response.body
    json_response = JSON.parse(Crack::XML.parse(xml_response).to_json)
    json_response["body"]
  when Net::HTTPRedirection then
    # redirect
    puts "\e[33m 302 redirect detected. following redirect... redirectLimit=#{redirectLimit}\e[0m"
    do_fetch(response['location'], redirectLimit - 1)
  else
    # error out
    puts "\e[31m Unexpected response! \e[0m"
    raise 'Unexpected response: ' + response.inspect
    # puts "Headers: #{response.to_hash.inspect}"
  end
end

# parsed format sample: {"24A" => [2, 4, 5], "24E" => [7, 9, 29, 33]}
def do_parse(data)
  #data = {"predictions"=>[{"direction"=>{"prediction"=>[{"epochTime"=>"1518489808605", "seconds"=>"183", "minutes"=>"3", "isDeparture"=>"false", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7770", "block"=>"24_35_142", "tripTag"=>"35800914"}, {"epochTime"=>"1518490260213", "seconds"=>"635", "minutes"=>"10", "isDeparture"=>"false", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7750", "block"=>"24_6_60", "tripTag"=>"35800915"}, {"epochTime"=>"1518490643547", "seconds"=>"1018", "minutes"=>"16", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7795", "block"=>"24_7_70", "tripTag"=>"35800916"}, {"epochTime"=>"1518491063547", "seconds"=>"1438", "minutes"=>"23", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"8160", "block"=>"24_41_90", "tripTag"=>"35800917"}, {"epochTime"=>"1518491543547", "seconds"=>"1918", "minutes"=>"31", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7712", "block"=>"24_8_80", "tripTag"=>"35800918"}], "title"=>"North - 24a Victoria Park towards Steeles"}, "agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"24-Victoria Park", "routeTag"=>"24", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992"}, {"agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"324-Victoria Park Night Bus", "routeTag"=>"324", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992", "dirTitleBecauseNoPredictions"=>"North - 324 Victoria Park Blue Night towards Steeles via Sheppard and Warden"}], "copyright"=>"All data copyright Toronto Transit Commission 2018."}
  #data = {"predictions"=>[{"direction"=>[{"prediction"=>{"epochTime"=>"1518503073899", "seconds"=>"3427", "minutes"=>"57", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24", "dirTag"=>"24_0_24da", "vehicle"=>"8147", "block"=>"24_55_292", "tripTag"=>"35800563"}, "title"=>"South - 24 Victoria Park towards Danforth via Victoria Park Station"}, {"prediction"=>[{"epochTime"=>"1518500206307", "seconds"=>"559", "minutes"=>"9", "isDeparture"=>"false", "branch"=>"24", "dirTag"=>"24_0_24A", "vehicle"=>"8941", "block"=>"24_33_152", "tripTag"=>"35800688"}, {"epochTime"=>"1518500813108", "seconds"=>"1166", "minutes"=>"19", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24", "dirTag"=>"24_0_24A", "vehicle"=>"7755", "block"=>"24_81_242", "tripTag"=>"35800689"}, {"epochTime"=>"1518501413108", "seconds"=>"1766", "minutes"=>"29", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24", "dirTag"=>"24_0_24A", "vehicle"=>"7750", "block"=>"24_6_60", "tripTag"=>"35800690"}, {"epochTime"=>"1518502013108", "seconds"=>"2366", "minutes"=>"39", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24", "dirTag"=>"24_0_24A", "vehicle"=>"7795", "block"=>"24_7_70", "tripTag"=>"35800691"}, {"epochTime"=>"1518502613108", "seconds"=>"2966", "minutes"=>"49", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24", "dirTag"=>"24_0_24A", "vehicle"=>"8112", "block"=>"24_41_90", "tripTag"=>"35800692"}], "title"=>"South - 24 Victoria Park towards Victoria Park Station"}], "agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"24-Victoria Park", "routeTag"=>"24", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"1401"}, {"agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"324-Victoria Park Night Bus", "routeTag"=>"324", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"1401", "dirTitleBecauseNoPredictions"=>"South - 324 Victoria Park Blue Night towards Kingston Rd"}], "copyright"=>"All data copyright Toronto Transit Commission 2018."}
  #data = {"predictions"=>[{"direction"=>[{"prediction"=>[{"epochTime"=>"1518570639711", "seconds"=>"252", "minutes"=>"4", "isDeparture"=>"false", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7864", "block"=>"24_10_100", "tripTag"=>"35800851"}, {"epochTime"=>"1518571253971", "seconds"=>"866", "minutes"=>"14", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7865", "block"=>"24_35_142", "tripTag"=>"35800903"}, {"epochTime"=>"1518571643547", "seconds"=>"1256", "minutes"=>"20", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7716", "block"=>"24_6_60", "tripTag"=>"35800904"}, {"epochTime"=>"1518572063547", "seconds"=>"1676", "minutes"=>"27", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7839", "block"=>"24_7_70", "tripTag"=>"35800905"}, {"epochTime"=>"1518572543547", "seconds"=>"2156", "minutes"=>"35", "isDeparture"=>"false", "affectedByLayover"=>"true", "branch"=>"24A", "dirTag"=>"24_1_24A", "vehicle"=>"7792", "block"=>"24_41_90", "tripTag"=>"35800906"}], "title"=>"North - 24a Victoria Park towards Steeles"}, {"prediction"=>{"epochTime"=>"1518570775194", "seconds"=>"387", "minutes"=>"6", "isDeparture"=>"false", "branch"=>"24E", "dirTag"=>"24_1_24E", "vehicle"=>"8113", "block"=>"24_81_242", "tripTag"=>"35800902"}, "title"=>"North - 24e Victoria Park towards Steeles"}], "agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"24-Victoria Park", "routeTag"=>"24", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992"}, {"agencyTitle"=>"Toronto Transit Commission", "routeTitle"=>"324-Victoria Park Night Bus", "routeTag"=>"324", "stopTitle"=>"Victoria Park Ave At Lawrence Ave East", "stopTag"=>"8992", "dirTitleBecauseNoPredictions"=>"North - 324 Victoria Park Blue Night towards Steeles via Sheppard and Warden"}], "copyright"=>"All data copyright Toronto Transit Commission 2018."}

  predictions = data['predictions']
  
  ret = Hash.new { |hash, key| hash[key] = [] }

  what = predictions.map { |route| [route['direction']] }.flatten.compact
  it = what.map{ |eh| [eh['prediction']] }.flatten.compact

  it.each do |wtf|
    branch = wtf['branch']
    mins = Integer(wtf['minutes'])
    ret[branch] << mins
  end

  ret
end