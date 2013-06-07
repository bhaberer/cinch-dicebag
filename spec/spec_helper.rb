require 'coveralls'
Coveralls.wear!
require 'cinch-dicebag'

def fake_bot
  bot = Cinch::Bot.new do
    configure do |c|
      c.plugins.options[Cinch::Plugins::Dicebag][:filename] = '/dev/null'
    end
  end
  bot.loggers.level = :fatal
  bot
  return bot
end

module Cinch
  module Plugin
    def initialize(opts = {})
      @bot = fake_bot
      @handlers = []
      @timers   = []
      # Don't init the bot
      # __register
    end
  end
end
