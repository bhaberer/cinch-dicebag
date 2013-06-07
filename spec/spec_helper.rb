require 'cinch-dicebag'
require 'coveralls'
Coveralls.wear!


def fake_bot
  bot = Cinch::Bot.new
  bot.loggers.level = :fatal
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
