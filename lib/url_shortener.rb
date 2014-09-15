require 'cinch'
require 'shutup'

require 'googl'
require 'mechanize'

class UrlShortener
  include Cinch::Plugin

  def initialize(*args)
    super
    @shutup = Shutup.instance
    @web_agent = Mechanize.new
    @web_agent.user_agent_alias = "Linux Mozilla"
    @web_agent.max_history = 0
    @web_agent.redirection_limit = 4

    # Hack to set Accept header to only allow (X)HTML responses
    @web_agent.pre_connect_hooks << lambda { |p, request|
        request['Accept'] = '*/html,*/xhtml,*/xml'
    }


    @url_client = Googl.client(config[:google_username], config[:google_password]);
  end

  # A bunch of this was stolen from
  # https://github.com/mpapis/cinch-url-scraper/blob/master/lib/cinch/plugins/urlscraper.rb
  listen_to :channel
  def listen(m)
      return if @shutup.shutup_in?(m.channel.to_s)
      URI.extract(m.message, ['http', 'https']) do |link|
        page = nil
        begin
          timeout(5) do
            page = @web_agent.get(link)
          end
        rescue Mechanize::ResponseCodeError
        rescue SocketError
          m.reply "Y u post broken links?"
          return
          next
        rescue Timeout::Error
          @bot.debug "URL timed out"
          return
        rescue
          @bot.debug "Failed to grab URL"
          @bot.debug $!.to_s
          @bot.debug $!.backtrace.join("\n")
          return
        end

        @bot.debug "Grabbing short title..."
        page_title = page.title.gsub(/[\x00-\x1f]*/, "").gsub(/[ ]{2,}/, " ").strip rescue nil
        @bot.debug "Shortening URL..."
        shortened_url = nil
        begin
            timeout(5) do
                shortened_url = @url_client.shorten(link)
            end 
        rescue Timeout::Error
            @bot.debug "URL shortener timed out"
            return
        rescue
            @bot.debug "Something went wrong. Couldn't shorten."
            return
        end

        @bot.debug "Building and sending reply..."
        reply_text = "Short: #{shortened_url.short_url}"

        uri = URI.parse(link)
        extra = ""
        #if uri.host.end_with?("youtube.com")
        #    views = page.search(".watch-view-count").children[0].to_s.strip
        #    extra = " [#{views} views]"
        #end


        reply_text += " - #{page_title}#{extra}"

        m.reply reply_text
      end
  end
end
