def getUri(type, pl_id=0)
  case type
  when LOGIN
    uri = BASE_URL + "/Users/login" + generateLogin()
  when GET_PLURKS
    uri = BASE_URL + "/Timeline/getPlurks" + generatePlurks()
  when GET_RESPONSE
    uri = BASE_URL + "/Responses/get" + generateResponse(pl_id)
  end
  return uri
end

def generateLogin()
  return "?api_key=#{API_KEY}&username=#{USERNAME}&password=#{PASSWORD}"
end

def generatePlurks()
  return "?api_key=#{API_KEY}&limit=100&only_user=#{@user_id}"
end

def generateResponse(id)
  return "?api_key=#{API_KEY}&plurk_id=#{id}"
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
  day_offset = Time.new.utc - DAY_SEC
  timezone_offset = TIMEZONE * HOUR_SEC
  @msg = ""
  parsed['plurks'].each { |e|
    pid = e['plurk_id']
    datetime = Time.parse(e['posted'])
    datetime = datetime.utc
    if datetime < day_offset then
      break
    end
    if IGNORE_PRIVATE_PLURKS then
      if e['plurk_type'] == 1 || e['plurk_type'] == 3 then #ignore private plurks
        next
      end
    end
    datetime += timezone_offset
    publisher = "#{TAB}#{@display_name} #{e['qualifier_translated']}: "
    tmpStr = formatToFit(publisher, e['content_raw'],ORIGINAL_NAME_COLOR,ORIGINAL_POST_COLOR)
    #puts tmpStr
    @msg << tmpStr << "\r\n"
    #@msg += "#{TAB}#{@display_name} #{e['qualifier_translated']}: #{e['content_raw']}\r\n"
    @msg += "#{TAB}#{PLURK_BASE_URL}#{pid.to_s(36)} - Posted at #{datetime.strftime("%H:%M")}\r\n\r\n"
    getResponse(e['plurk_id'])
    @msg += "\r\n"
  }
  @msg += "---\r\nblurk #{VERSION} by Bruce Hsu, http://github.com/brucehsu/blurk"
  #@msg = @msg.encode('big5-uao')
  sendMsg()
  #puts @msg
end

def getResponse(id)
  req = open(getUri(GET_RESPONSE, id), "Cookie" => @cookie)
  parsed = JSON.parse(req.read())
  parsed['responses'].each { |e|
    user_id = e['user_id']
    display_name = parsed['friends']["#{user_id}"]['display_name']
    responser = "#{TAB}#{TAB}#{display_name} #{e['qualifier_translated']}: "
    tmpStr = formatToFit(responser, e['content_raw'],DISPLAY_NAME_COLOR,CONTENT_COLOR)
    @msg += tmpStr + "\r\n"
  }
  @msg += "\r\n"
end

def formatPlurks()
  
end

def formatToFit(publisher, content,pcolor,ccolor)
  pcolor_start = ''
  pcolor_start << 27 << '[m' << 27 << "[1;#{pcolor}m"
  pcolor_end = ''
  pcolor_end << 27 << '[m'
  ccolor_start = ''
  ccolor_start << 27 << '[m' << 27 << "[1;#{ccolor}m"
  ccolor_end = ''
  ccolor_end << 27 << '[m'
  tmpStr = "#{pcolor_start}#{publisher}#{pcolor_end}#{ccolor_start}#{content}"
  tmpStr = @ic.conv(tmpStr)
  byteCount = 0
  tmpStr.each_byte { |byte|
    byteCount += 1
  }
  byteCount += pcolor_start.length*2 + pcolor_end.length
  if byteCount > LINE_MAX + pcolor_start.length*2 + pcolor_end.length then
    newStr = ''
    tbyteCount = 0
    tmpStr.each_byte { |b|
      tbyteCount += 1
      if b>=161 then
        if tbyteCount == LINE_MAX + pcolor_start.length*2 + pcolor_end.length then
          newStr << ccolor_end << "\r\n" << ccolor_start << generateSpace(@ic.conv(publisher))
        end
        newStr << b
        next
      end
      newStr << b
      if tbyteCount == LINE_MAX + pcolor_start.length*2 + pcolor_end.length then
        newStr <<  ccolor_end << "\r\n" << ccolor_start<< generateSpace(@ic.conv(publisher))
      end
    }
    tmpStr = newStr
  end
  return tmpStr + ccolor_end
end

def generateSpace(src)
  space = ""
  src.each_byte { |byte|
    space << ' '
  }
  return space
end

def sendMsg()
  #ic = Iconv.new("big5-hkscs//IGNORE", "utf-8")
  #@msg = ic.iconv(@msg)
  @display_name = @ic.conv(@display_name)
  message = <<MESSAGE_END
Subject: #{@display_name}'s Plurk (#{@start_time.strftime("%Y/%m/%d")})

#{@msg}
MESSAGE_END
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  Net::SMTP.start(SMTP_SERVER,
    SMTP_SERVER_PORT,
    'localhost',
    EMAIL_ACCOUNT, EMAIL_PASSWORD , :plain) do |smtp|
    smtp.send_message message, EMAIL_ADDRESS,
      FORWARD_ADDRESS
  end
end
