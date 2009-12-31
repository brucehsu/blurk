# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'json'
require 'net/http'
require 'net/smtp'
require 'open-uri'
require 'openssl'
require 'iconv'
require 'base64'
require 'date'
require 'pp'
require 'methods.rb'
require 'conf.rb'

VERSION = "0.1 Beta"
HOUR_SEC = 3600
DAY_SEC = 86400
LINE_MAX = 78
TAB = '    '

@start_time = Time.new.localtime
@ic = Iconv.new("big5-hkscs//IGNORE", "utf-8")
login()
getPlurks()