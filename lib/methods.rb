def getUri(type)
  case type
  when LOGIN
    uri = BASE_URL + "/Users/login" + generateLogin()
  when GET_PLURKS
    uri = BASE_URL + "/Timeline/getPlurks" + generatePlurks()
  end
  return uri
end

def generateLogin()
  return "?api_key=#{API_KEY}&username=#{USERNAME}&password=#{PASSWORD}"
end

def generatePlurks()
  return "?api_key=#{API_KEY}&limit=100&only_user=#{@user_id}"
end

def login()
	req = open(getUri(LOGIN))
  @cookie = req.meta['set-cookie'].split("; ",2)[0]
  parsed = JSON.parse(req.read())
  @user_id = parsed['user_info']['id']
  @display_name = parsed['user_info']['display_name']
end

def getPlurks()
  req = open(getUri(GET_PLURKS), "Cookie" => @cookie)
  parsed = JSON.parse(req.read())
  parsed['plurks'].each { |e|
    puts "(#{e['posted']}) #{@display_name} #{e['qualifier_translated']}: #{e['content_raw']}"
  }
end