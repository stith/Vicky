require 'cinch'

require 'shutup'
require 'net/http'
require 'uri'

class Bitcoin
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
  end


  match /^(?:\<([^>]*)\> )?(?:vicky,? )bitcoin/i
  def execute(m)
    return if @shutup.shutup_in?(m.channel.to_s)
    uri = URI.parse("https://data.mtgox.com/api/1/BTCUSD/ticker")

    response = ''
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request['User-Agent'] = "Vicky IRC bot, Ruby, via Cinch"
        response = http.request request
    end

    ticker = JSON.parse(response.body)

    historical_json = Net::HTTP.get_response(URI.parse("http://api.bitcoincharts.com/v1/weighted_prices.json"))
    historical = JSON.parse(historical_json.body)

    result = ticker['return']
    last = result['last']
    current = last['value'].to_f
    day = historical["USD"]["24h"].to_f
    if (day > current)
        trend = 'down'
    else
        trend = 'up'
    end


    m.reply "1 bitcoin is currently worth $" + current.to_s + ". 24-hour trend is " + trend + "."
  end
end
