require 'cinch'

class Identify
  include Cinch::Plugin

  listen_to :connect, method: :identify
  def identify(m)
    @bot.debug "Identifying with NickServ"
    User("NickServ").send("identify %s %s" % [config[:username], config[:password]])
  end
end
