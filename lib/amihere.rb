require 'cinch'

require 'shutup'

class Amihere
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
    @replies = [
      "Mhm.",
      "Sure am.",
      "Always.",
      "Did I do something wrong?"
    ]
  end


  match /^(?:\<([^>]*)\> )?(?:are )?you (?:still )?t?here,? vicky/i, :method => :stillhere
  match /^(?:\<([^>]*)\> )?vicky,? (?:are )?you (?:still )?t?here/i, :method => :stillhere
  def stillhere(m,ingame_name)
    return if @shutup.shutup_in?(m.channel.to_s)
    m.reply @replies.sample
  end

  match /^(?:\<([^>]*)\> )?vicky$/i, :method => :attention
  def attention(m,ingame_name)
    return if @shutup.shutup_in?(m.channel.to_s)
    m.reply "What?"
  end
end
