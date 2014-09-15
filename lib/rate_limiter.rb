require 'cinch'

class RateLimiter
  include Cinch::Plugin

  def initialize(*args)
    super
    @allowances = {}
    @already_kicked = []
    @counter = 0
  end
  
  listen_to :channel
  def listen(m)
    return @bot.config.ircbots.include? m.user.nick
    return if m.user.nick == @bot.config.nick

    @allowances[m.user.nick] = config[:rate] unless @allowances.key?(m.user.nick)

    @allowances[m.user.nick] -= 1

    if @allowances[m.user.nick] <= 0
      return if m.user.authed? and @bot.config.admins.include?(m.user.nick)
      if @already_kicked.include?(m.user.nick)
        m.reply "I SAID STFU"
        if config[:testmode]
          m.reply "#{m.user.nick} would be banned if we weren't in test mode"
        else
          m.channel.ban(m.user)
          m.channel.kick(m.user)
        end
      else
        m.reply "STFU #{m.user.nick}"
        if config[:testmode]
          m.reply "#{m.user.nick} would be kicked if we weren't in test mode"
          @allowances[m.user.nick] = config[:rate]
        else
          m.channel.kick(m.user)
        end
        @already_kicked << m.user.nick
      end
    end
  end

  timer 1, method: :reset_allowances
  def reset_allowances
      @counter += 1
      if @counter <= config[:rate]
        return
      end
      @counter = 0

      @allowances.each do |user,left|
        @allowances[user] = config[:rate]
      end
  end
end
