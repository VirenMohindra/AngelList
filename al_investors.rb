require 'net/http'
require 'json'
require 'csv'

###############################

list_of_urls = %Q(
https://angel.co/work-market
https://angel.co/hailo
https://angel.co/hullabalu
https://angel.co/mobli
https://angel.co/timehop
https://angel.co/hireart
https://angel.co/chartbeat
https://angel.co/kitchensurfing
https://angel.co/jukely
https://angel.co/nomi
https://angel.co/okpanda
https://angel.co/oyster
https://angel.co/picturelife
https://angel.co/canvas
https://angel.co/abacus
https://angel.co/memoir
https://angel.co/makespace
https://angel.co/shake-1
https://angel.co/electric-objects
https://angel.co/cover
https://angel.co/draft-11
https://angel.co/skillshare
https://angel.co/launchrock
https://angel.co/captricity
https://angel.co/disqus
https://angel.co/days-by-wander
https://angel.co/amicus
https://angel.co/hinge
https://angel.co/bondsy
https://angel.co/poptip
https://angel.co/tutorspree
https://angel.co/secondmarket
https://angel.co/rewind-me
https://angel.co/adstruc
https://angel.co/stack-exchange
https://angel.co/yext
https://angel.co/snagfilms
https://angel.co/opensky
https://angel.co/energyhub
https://angel.co/rent-the-runway
https://angel.co/yieldbot
https://angel.co/betterment
https://angel.co/billguard
https://angel.co/onswipe
https://angel.co/shelby-tv
https://angel.co/next-new-networks
https://angel.co/amino-apps
https://angel.co/onename
https://angel.co/transferwise
https://angel.co/angellist
https://angel.co/blue-apron
https://angel.co/taykey
https://angel.co/spring-3
https://angel.co/movable-ink
https://angel.co/fancy
https://angel.co/artsicle
https://angel.co/apprenda-1
https://angel.co/imrsv
https://angel.co/songza
https://angel.co/floored
https://angel.co/buynow-worldwide
https://angel.co/estimote
https://angel.co/appboy
https://angel.co/yotpo
https://angel.co/truveris
https://angel.co/classpass
https://angel.co/matter-io
https://angel.co/decisive
https://angel.co/docphin
https://angel.co/triplelift
https://angel.co/signal360-formerly-sonic-notify
https://angel.co/assured-labor
https://angel.co/20x200
https://angel.co/manicube
https://angel.co/sundaysky
https://angel.co/paddle8
https://angel.co/sefaira
https://angel.co/solvebio
https://angel.co/breather
https://angel.co/plated
https://angel.co/cord
https://angel.co/pilot-5
https://angel.co/fitocracy
https://angel.co/dash
https://angel.co/directly
https://angel.co/theskimm
https://angel.co/whosay
https://angel.co/wonolo
https://angel.co/cleanly
https://angel.co/datadog
https://angel.co/valet-anywhere
https://angel.co/fundera
https://angel.co/hightower
https://angel.co/kinsa
https://angel.co/canary-1
https://angel.co/copromote
https://angel.co/reonomy
https://angel.co/gochime
https://angel.co/synthesio-1
https://angel.co/updater
)

access_token = "1b35c867acc8f51e94e8db709e82c0f01e9e944e76d1b433"

###############################

array_of_urls = list_of_urls.split(/\n/)
array_of_urls.reject! {|a| a.empty? }

def get_request(url, params)
  uri = URI(url)
  uri.query = URI.encode_www_form(params)
  begin
    res = Net::HTTP.get_response(uri)
    return JSON.parse(res.body)
  rescue
    puts "Could not make request to #{url} with #{params}"
    if res && res.body
      puts "Response was: #{res.body}"
    end
    return false
  end
end

def get_al_details(url, access_token)
  startup_roles = nil
  id = nil

  slug = url.split(".co/")[1]
  params = { :type => 'Startup', :query => slug, :access_token => access_token}
  request_url = "https://api.angel.co/1/search"
  startup_results = get_request(request_url, params)
  startup_results.each do |startup_result|
    if startup_result['url']==url
      id = startup_result['id']
    end
  end
  if id 
    params = {:access_token => access_token}
    url = "https://api.angel.co/1/startups/#{id}/roles"
    startup_roles = get_request(url,params)
  end

  return startup_roles
end

csv = CSV.open("investor_names.csv", "wb")
csv << ["name", "website", "angellist url"]

roles_array = Array.new

array_of_urls.each do |url|
  url.strip!
  startup_roles = get_al_details(url, access_token)

  if startup_roles
    startup_roles["startup_roles"].each do |role|
      if role && (role["role"] == "past_investor" || role["role"] == "investor")
        if role["tagged"]
          name = role["tagged"]["name"]
          url = role["tagged"]["company_url"]
          al_url = role["tagged"]["angellist_url"]

          if role["tagged"]["type"] != "User"
            sleep 1
            vc_roles = get_al_details(al_url, access_token)

            if vc_roles && vc_roles["startup_roles"]
              vc_roles["startup_roles"].each do |role|
                if role && (role["role"] == "founder" || role["role"] == "employee")
                  name = role["tagged"]["name"]
                  al_url = role["tagged"]["angellist_url"]

                  unless roles_array.include?(name)
                    roles_array << name
                    csv << [name, url, al_url]
                  end
                end
              end
            end
          end
        end

        unless roles_array.include?(name)
          roles_array << name
          csv << [name, url, al_url]
        end
      end
    end
  end
  sleep rand(5)
end
