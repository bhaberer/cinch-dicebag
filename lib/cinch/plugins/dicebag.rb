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

      attr_accessor :storage

      self.help = 'Roll a random bag of dice with .dicebag, you can also ' \
                  'use .roll (dice count)d(sides) to roll specific dice ' \
                  '(e.g. .roll 4d6 3d20)'

      match(/dicebag\z/, method: :dicebag)
      match(/dicebag stats/, method: :stats)
      match /roll(?:\s(.*))/, method: :roll
      match /roll\z/, method: :roll

      def initialize(*args)
        super
        @storage = Cinch::Storage.new(config[:filename] || 'yaml/dice.yml')
        @bag = Bag.new(4 => 250, 6 => 500, 10 => 750, 20 => 1000)
      end

      # Roll a random assortment of dice, total the rolls, and record the score.
      # @param [String] nick Nickname of the user rolling.
      # @param [Cinch::Channel] channel The Channel object where the roll took
      #   place.
      # @return [String] A description of the roll that took place
      def dicebag(m)
        return if Cinch::Toolbox.sent_via_private_message?(m)

        @bag.roll
        user = m.user.nick.downcase
        channel = m.channel.name
        m.reply "#{m.user.nick} rolls a #{@bag.size} bag of dice totalling " \
                "#{@bag.score}. #{score_check(user, channel, @bag.score)}"
      end

      def stats(m)
        return if Cinch::Toolbox.sent_via_private_message?(m)

        m.user.send 'Top ten dicebag rolls:'
        top10 = top_ten_rolls(m.channel.name)
        top10.each_with_index do |r, i|
          m.user.send "#{i + 1} - #{r.first} [#{r.last}]"
        end
      end

      # Roll a specific set of dice and return the pretty result
      # @param [String] nick Nickname of the user rolling.
      # @param [String] dice Space delimited string of dice to role.
      #   (i.e. '6d12 4d20 d10'
      # @return [String] String describing the dice that were rolled
      def roll(m, dice = '1d20')
        result = Die.roll(dice.split(' '))
        if result.is_a?(Integer)
          result = "#{m.user.nick} rolls #{dice} totalling #{result}"
        end
        m.reply result
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
