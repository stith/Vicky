require 'cinch'

require 'shutup'

class Op
  include Cinch::Plugin
  def initialize(*args)
    super
    @shutup = Shutup.instance
  end

  match /^vicky, (op|deop) ([^ ]*)/i

  def execute(m,operation,to_auth)
    # Only allow authed admins in IRC
    if @bot.config.ircbots.include?(m.user.nick)
        @bot.debug "IRCBot can't request OP"
        return
    end
    unless m.user.authed?
        @bot.debug "#{m.user.nick} not authed"
        return
    end
    unless @bot.config.admins.include? m.user.nick
        @bot.debug "#{m.user.nick} isn't in admins list"
        return
    end

    unless m.channel.has_user? to_auth or to_auth=='me'
      m.reply "Can't find #{to_auth}!" unless @shutup.shutup_in?(m.channel.to_s)
      return
    end

    # Send is for dynamic method calling, so we can just pass
    # the operation matched in the regular expression instead
    # of branching our conditions again
    if to_auth=='me'
      @bot.debug "#{operation}ing #{m.user}"
      m.channel.__send__ operation.to_sym, m.user
    else
      @bot.debug "#{operation}ing #{to_auth}"
      m.channel.__send__ operation.to_sym, to_auth
    end
    m.reply "You're the boss."
  end

end
