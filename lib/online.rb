require 'cinch'

require 'shutup'
require 'gamespy_query'

class Online
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
  end

  match /^(vicky,? )?who(\'?s| is) online/i

  def execute(m)
    return if @shutup.shutup_in?(m.channel.to_s)

    players = []
    config[:servers].each do |server, addr|
      query = GamespyQuery::Socket.new(addr)
      response = query.sync

      if response["players"] 
        response["players"].each do |player|
          players << player[:name]
        end
      end
    end

    player_list = players.join(", ")
    if players.count > 15
      m.reply "#{players.count} players, results PM'd."
      m.user.send "#{players.count} people: #{player_list}"
    elsif players.count == 1
      m.reply "1 person: #{player_list}"
    elsif players.count == 0
      m.reply "Nobody."
    else
      m.reply "#{players.count} people: #{player_list}"
    end
  end

  match /^(vicky,? )?ho(\'?s| is) online/i, :method => :ho
  def ho(m)
      m.reply "Yous a ho. http://www.youtube.com/watch?v=0JsUb7c-Dqo"
  end

  
end
