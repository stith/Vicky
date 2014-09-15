require 'singleton'
require 'ago'

class Shutup
  include Singleton
  def initialize
    @shutup = Hash.new
    @shutup_expire = Hash.new
  end

  def shutup_in(time,channel)
    @shutup[channel] = Time.now
    @shutup_expire[channel] = time.from_now
  end

  def shutup_in?(channel)
    return false unless @shutup.has_key?(channel)
    @shutup[channel] = false if @shutup_expire[channel] <= Time.now
    !!@shutup[channel]
  end
end
