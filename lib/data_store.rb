require 'singleton'
require 'redis'
require 'time'

class DataStore
  include Singleton
  def initialize
    @namespace = ""
    @connected = false
    @redis = Redis.new
  end
  
  def namespace=(value)
    @namespace = value
  end
  
  def update_last_said(user,location,text)
    # Add the user if they don't exist in our autocomplete list
    matches = user_matches(user.downcase)
    if !matches or matches.length == 0
      add_user user
    end
    
    @redis.set key_for([user.downcase, 'said', 'user']), user.strip
    @redis.set key_for([user.downcase, 'said', 'location']), location.strip
    @redis.set key_for([user.downcase, 'said', 'text']), text.strip
    @redis.set key_for([user.downcase, 'said', 'time']), Time.now.to_s
  end
  
  def last_said(user)
    matches = user_matches(user.downcase)
    if (matches.length == 0)
      return false
    elsif (matches.length > 1)
      # If we have an exact match use that
      match = matches.select {|m| m.downcase == user.downcase}
      # Otherwise return an array of names
      if match.length != 1
        result = {}
        result[:result] = :multi
        result[:matches] = matches
        return result
      end
      match = match.first
    else
      match = matches.first
    end

    
    result = {}
    result[:user] = @redis.get key_for([match, 'said', 'user'])
    result[:location] = @redis.get key_for([match, 'said', 'location'])
    result[:text] = @redis.get key_for([match, 'said', 'text'])
    result[:time] = Time.parse(@redis.get key_for([match, 'said', 'time']))
    return result
  end
  
  # Adds autocomplete-style completion, for partial name lookups
  # From http://antirez.com/post/autocomplete-with-redis.html
  def add_user(user)
    user = user.strip.downcase
    key = key_for('autocomplete')
    (1..(user.length)).each{ |l|
      prefix = user[0...l]
      @redis.zadd(key,0,prefix)
    }
    @redis.zadd(key,0,user+'*')
  end
  
  # Gets users in our autocomplete set
  def user_matches(search,count=false)
    results = []
    rangelen = 17 # Max minecraft username length is 16, add 1 for * entry
    count = 5 unless count # Most of the time we aren't returning results if there is more than 1 match anyways
    key = key_for('autocomplete')
    start = @redis.zrank(key.to_sym, search)
    return [] if !start
    
    while results.length != count
      range = @redis.zrange(key,start,start+rangelen-1)
      start += rangelen
      break if !range or range.length == 0
      range.each { |entry| 
        minlen = [entry.length, search.length].min
        if entry[0...minlen] != search[0...minlen]
          count = results.count
          break
        end
        if entry[-1..-1] == '*' and results.length != count
          results << entry[0...-1]
        end
      }
    end
    
    return results
  end
  
  # Gets a namespaced key
  def key_for(key)
    key_parts = []
    key_parts << @namespace if @namespace && @namespace.length > 0
    
    # Gracefully handles arrays passed here as well, due to the flatten
    key_parts << key
    key_parts.flatten.join ':'
  end

  def remove_user(username)
    matches = user_matches(username.downcase)
    if matches.length == 1
        # 1 match exactly. delete it.
        match = matches.first
        @redis.del key_for([match, 'said', 'user'])
        @redis.del key_for([match, 'said', 'location'])
        @redis.del key_for([match, 'said', 'text'])
        @redis.del key_for([match, 'said', 'time'])
        @redis.zrem key_for('autocomplete'), username.downcase + "*"
        return true
    else
        return false
    end
  end
end
