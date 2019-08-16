require 'zabby'
require 'json'
# require 'active_support/core_ext/numeric/time'

  swarn = []
  savrg = []
  shgh = []
  sdis = []

  twarn = 0
  tavrg = 0
  thgh = 0
  tdis = 0

  lav_warn = 0
  lav_avrg = 0
  lav_hgh = 0
  lav_dis = 0

SCHEDULER.every '10s' do

  serv = Zabby.init do
    set :server => ENV['ZABBIX_SERVER']
    set :user => ENV['ZABBIX_USERNAME']
    set :password => ENV['ZABBIX_PASSWORD']
    login
  end

  env = serv.run { Zabby::Trigger.get "filter" => { "priority" => [ 2, 3, 4, 5 ] }, "output" => "extend", "only_true" => "true", "monitored" => 1, "withUnacknowledgedEvents" => 1, "skipDependent" => 1, "expandData" => "host" } 
  
  pas = JSON.parse(env.to_json)
  
  pas.each do |res|
    #puts res
    prio = res["priority"]
    prio = 2
    lstchnge = res["lastchange"]
    description = res["description"]
    alertime = Time.at(lstchnge.to_i)
    
    #adjust the pref. time 
    # timelapse = Time.now - 1.hours
    swarn = []
    swarn << description
        
  end

  lav_warn = twarn
  lav_avrg = tavrg
  lav_hgh = thgh
  lav_dis = tdis

  twarn = swarn.count 
  tavrg = savrg.count 
  thgh = shgh.count 
  tdis = sdis.count 

  warn = twarn - lav_warn 
  avrg = tavrg - lav_avrg
  hgh = thgh - lav_hgh 
  dis = tdis - lav_dis 

  if twarn > 0 then warnstats = "warn" else warnstats = "ok" end
  if avrg > 0 then avrgstats = "average" else avrgstats = "ok" end
  if hgh > 0 then hghstats = "high" else hghstats = "ok" end
  if dis > 0 then disstats = "disaster" else disstats = "ok" end
  send_event( 'outwarn', { current: warn, last: lav_warn, status: warnstats, description: swarn } )
#  send_event( 'outavrg', { current: avrg, last: lav_avrg, status: avrgstats } )
#  send_event( 'outhigh', { current: hgh, last: lav_hgh, status: hghstats  } )
#  send_event( 'outdis', { current: dis, last: lav_dis, status: disstats  } )
  
end