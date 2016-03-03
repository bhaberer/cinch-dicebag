# -*- coding: utf-8 -*-
require 'cinch'
require 'cinch/toolbox'
require 'cinch/cooldown'
require 'cinch/storage'
require 'time-lord'

module Cinch
  module Plugins
    # Cinch Plugin to allow dice rolling.
    class Dicebag
      include Cinch::Plugin

      enforce_cooldown

      attr_accessor :storage

      self.help = 'Roll a random bag of dice with .dicebag, you can also ' \
                  'use .roll (dice count)d(sides) to roll specific dice ' \
                  '(e.g. .roll 4d6 3d20)'

      match(/dicebag\z/, method: :dicebag)
      match(/dicebag stats/, method: :stats)
      match(/roll(?:\s(.*))/, method: :roll)
      match(/roll\z/, method: :roll)

      def initialize(*args)
        super
        # initialize storage
        @storage = Cinch::Storage.new(config[:filename] || 'yaml/dice.yml')

        # Create a bag of dice, pass a hash of the maxcount for each type
        #   for random rolls.
        @bag = Bag.new(4 => 250, 6 => 750, 10 => 1500, 20 => 2000)
      end

      # Roll a random assortment of dice, total the rolls, and record the score.
      # @param [Message] message Nickname of the user rolling.
      # @return [String] A description of the roll that took place
      def dicebag(message)
        return if Cinch::Toolbox.sent_via_private_message?(message)

        @bag.roll
        user = message.user.nick
        channel = message.channel.name
        message.reply "#{user} rolls a #{@bag.size} bag of dice totalling " \
                      "#{@bag.score}. #{score_check(user, channel, @bag.score)}"
      end

      def stats(message)
        return if Cinch::Toolbox.sent_via_private_message?(message)

        message.user.send 'Top ten dicebag rolls:'
        top10 = top_ten_rolls(message.channel.name)
        top10.each_with_index do |r, i|
          message.user.send "#{i + 1} - #{r.first} [#{r.last}]"
        end
      end

      # Roll a specific set of dice and return the pretty result
      # @param [String] nick Nickname of the user rolling.
      # @param [String] dice Space delimited string of dice to role.
      #   (i.e. '6d12 4d20 d10'
      # @return [String] String describing the dice that were rolled
      def roll(message, dice = '1d20')
        result = Die.roll(dice.split(' '))
        if result.is_a?(Integer)
          result = "#{message.user.nick} rolls #{dice} totalling #{result}"
        end
        message.reply result
      end

      private

      def top_ten_rolls(channel)
        scores = @storage.data[channel].dup
        scores.sort { |a, b| b[1][:score] <=> a[1][:score] }
              .map { |s| [s.first, s.last[:score]] }[0..9]
      end

      # Score checker for Dicebag rolls. Checks a given user/channel/score
      #   against the current high score for that user.
      # @param [String] nick Nickname of the user who rolled the score.
      # @param [String] channel Name of the channel where the roll was made.
      # @param [Fixnum] score The score from the bag.
      # @return [String] If the new score is higher, returns an announcement
      #   to that effect, otherwise returns a blank string.
      def score_check(nick, channel, score)
        nick = nick.downcase
        # If the chennel or nick are not already initialized, spin them up
        @storage.data[channel] ||= {}
        @storage.data[channel][nick] ||= { score: score, time: Time.now }

        # Check and see if this is a higher score.
        old = @storage.data[channel][nick]
        return '' unless @storage.data[channel][nick][:score] < score

        @storage.data[channel][nick] = { score: score, time: Time.now }
        @storage.synced_save(@bot)
        "A new high score! Their old high roll was #{old[:score]}, " \
          "#{old[:time].ago.to_words}."
      end
    end
  end
end
