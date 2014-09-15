require 'cinch'

require 'shutup'

class Admin
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
  end


  match /^vicky,? (kick|ban) ([^ ]*)$/i
  def execute(m, dowhat, username)
    @bot.debug "Trying to #{dowhat} #{username}"
    return if @shutup.shutup_in?(m.channel.to_s)
    return unless m.channel.voiced? m.user
    m.reply "HADOUKEN!"
    if dowhat == 'kick'
      m.channel.kick username
    elsif dowhat == 'ban'
      m.channel.ban username
    end
  end
end
