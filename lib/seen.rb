require 'cinch'
require 'time-ago-in-words'

require 'shutup'
require 'data_store'

class Seen
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
    @data_store = DataStore.instance
    # Redis doesn't always update immediately, so store
    # a simple array in memory to avoid duplicate welcomes
    @already_welcomed = []
  end

  # Listen keeps track of user chat
  listen_to :channel
  def listen(m)
    if @bot.config.ircbots.include?(m.user.nick)
      # If the chat is coming from one of our IRC bots,
      # grab the in-game username
      regex = /\<([^>]*)\> (.+)/
      tested_message = m.message
      tested_message = "<nobody> no text" unless m.message =~ regex
      user = tested_message.match(regex)[1]
      location = @bot.config.botmap[m.user.nick.gsub(/[0-9]/, '')]
      message = tested_message.match(regex)[2]
    else
      # Otherwise they're just in IRC, so user their name.
      user = m.user.nick.downcase
      location = m.channel.to_s
      message = m.message
    end
    
    # If the user is returning after a long time away,
    # welcome them back!
    previous = @data_store.last_said(user)
    if previous
        seconds = Time.now - previous[:time]
        if seconds > 60*60*24*31 and not @already_welcomed.include?(user)
            m.reply "Welcome back, #{user}! The last time we saw you was #{previous[:time].ago_in_words.strip}!"
            m.reply "The last thing you said was: <#{previous[:user]}> #{previous[:text]}"
            @already_welcomed << user
        end
    end

    # Then update stuff
    @data_store.update_last_said(user, location, message)
  end

  # Execute is when a user is requesting a lookup
  # TODO: Generalize this to any bot name
  match /^(?:\<([^>]*)\> )?(?:vicky,? )?have you seen ([^?]+)/i
  def execute(m, ingame_name, name)
    return if @shutup.shutup_in?(m.channel.to_s)
    # Ignore short queries
    return if name.length <= 2
    # Get the right sender if sent from IRC
    if ingame_name
      sender = ingame_name
    else
      sender = m.user.nick
    end

    # If the query includes a space it was probably an unintentional lookup
    # Reply anyways in case it's funny
    if name.include? " "
      # Change "my X" to "your X" for lulz
      my_match = name.match(/^my (.*)$/i)
      your_match = name.match(/^your (.*)$/i)
      yourself_match = name.match(/^yourself (.*)$/i)
      if my_match
        m.reply "Nope, haven't seen your #{my_match[1]}"
        return
      elsif your_match
        m.reply "Nope, haven't seen my #{your_match[1]}"
        return
      elsif yourself_match
        m.reply "Nope, haven't seen myself #{yourself_match[1]}"
        return
      else
        m.reply "Nope, haven't seen #{name}"
        return
      end
    end
    
    
    if name.downcase == @bot.nick.downcase
      m.reply [
          "I'm right here.",
          "Vicky was last seen in my mirror this morning.",
          "Uhhhhhhhhhhhhhhhhhhh yes."
      ].sample
      return
    elsif sender.downcase == name.downcase
      m.reply [
          "You're right here.",
          "#{name} hasn't been seen since they lost their sense of self-identity.",
          "Turn around, they're behind you!"
      ].sample
      return
    end
    
    
    said = @data_store.last_said(name)
    
    if said === false
      # Got an false, meaning no results
      m.reply "Nope, haven't seen #{name}."
    elsif said[:result] == :multi
      # Got an array of matches
      m.reply "Name is too vague, be a bit more specific please. Matches: #{said[:matches].join(', ')}"
    else
      if said[:location][0] == "#"
        location = "in the IRC channel #{said[:location]}"
      elsif said[:location] == "ingame"
        # Old format
        location = "in-game on nobullcraft.com"
      else
        location = "in-game on #{said[:location]}"
      end
      m.reply "#{said[:time].ago_in_words.strip} #{location.strip}: <#{said[:user]}> #{said[:text]}"
    end
  end

  
  match /^(?:\<([^>]*)\> )?vicky,? forget about ([^?]+)/i, :method => :delete_user
  def delete_user(m, ingame_name, username)
    return if ingame_name
    if @bot.config.ircbots.include?(m.user.nick)
      @bot.debug "IRCBot can't request forgets"
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

    if @data_store.remove_user username
        m.reply [
            "I don't even know who you're talking about anymore.",
            "Okay.",
            "Done.",
            "It's like they were never even here."
        ].sample
    else
        m.reply "Not happening. Dunno why."
    end
  end
  
end
