$:.push File.expand_path(File.dirname(__FILE__) + '/lib')

require 'cinch'
require 'ago'

require 'data_store.rb'
require 'identify.rb'
require 'seen.rb'
require 'online.rb'
require 'rate_limiter.rb'
require 'op.rb'
require 'amihere.rb'
require 'admin.rb'
require 'url_shortener.rb'
require 'bitcoin.rb'

require 'shutup'

bot = Cinch::Bot.new do
  
  configure do |c|
    # IRC server to connect to
    c.server = "1.2.3.4"
    c.nick = "Vicky"
    c.user = "Vicky"
    c.realname = "Vicky bot"
    c.channels = ["#nobullcraft"]
    c.plugins.prefix = ''
    c.plugins.plugins = [
      UrlShortener,
      Identify,
      Seen,
      Online,
      RateLimiter,
      Op,
      Amihere,
      Admin,
      Bitcoin
    ]
    # A valid Google account
    c.plugins.options[UrlShortener] = {
      :google_username => "someone@gmail.com",
      :google_password => "hunter2"
    }
    # NickServ identification info
    c.plugins.options[Identify] = {
      :username => "Vicky",
      :password => "hunter2"
    }
    c.plugins.options[Online] = {
        :servers => {
            "nobullcraft.com"   => "127.0.0.1:25575",
            "craft.cat"         => "127.0.0.1:25577",
            "vicky.nobullcraft.com" => "127.0.0.1:25576"
        }
    }
    c.plugins.options[RateLimiter] = {
      :rate => 5, # Messages
      :per => 2,   # seconds
      :testmode => false
    }
    c.ircbots = ["NBCIRC", "CCIRC", "NBCHUB", "CNBC"]
    c.botmap = {
        'NBCIRC' => 'nobullcraft.com',
        'CCIRC' => 'craft.cat',
        'NBCHUB' => 'vicky.nobullcraft.com',
        'CNBC' => 'creative.nobullcraft.com'
    }

    c.admins = ["Seventoes","HandBanana","TheBlackCracka"]
    @authed = false
    @authuser = nil
    @shutup = Shutup.instance
    c.default_shutup = 1.minute
    
    @data_store = DataStore.instance
    @data_store.namespace = "vicky"
  end

  on :message, /^(\<[^>]*\> )?vicky(?:,|:) shut ?(?:(?:da|the) fuck )?up(?: for (1?[0-9]) minutes?)?$/i do |m, ingame_name, length|
    @shutup = Shutup.instance unless @shutup
    return if @shutup.shutup_in?(m.channel.to_s)
    m.reply "K"
    if length
      @bot.debug "Shutting up for #{length} minutes"
      @shutup.shutup_in(length.to_i.minutes, m.channel.to_s)
    else
      @bot.debug "Shutting up with default time: #{bot.config.default_shutup}"
      @shutup.shutup_in(bot.config.default_shutup, m.channel.to_s)
    end
  end

end

bot.start
