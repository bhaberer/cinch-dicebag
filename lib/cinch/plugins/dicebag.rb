# -*- coding: utf-8 -*-
require 'cinch'
require 'cinch/toolbox'
require 'cinch/cooldown'
require 'cinch/storage'
require 'time-lord'

module Cinch::Plugins
  # Cinch Plugin to allow dice rolling.
  class Dicebag
    include Cinch::Plugin

    enforce_cooldown

    attr_accessor :storage

    self.help = 'Roll a random bag of dice with .dicebag, you can also ' +
                'use .roll (dice count)d(sides) to roll specific dice ' +
                '(e.g. .roll 4d6 3d20)'

    match /dicebag/,        method: :dicebag
    match /roll(?:\s(.*))/, method: :roll
    match /roll\z/,         method: :roll

    def initialize(*args)
      super
      @storage = Cinch::Storage.new(config[:filename] || 'yaml/dice.yml')
    end

    # Roll a random assortment of dice, total the rolls, and record the score.
    # @param [String] nick Nickname of the user rolling.
    # @param [Cinch::Channel] channel The Channel object where the roll took
    #   place.
    # @return [String] A description of the roll that took place
    def dicebag(m)
      if m.channel.nil?
        m.reply 'You must use that command in the main channel'
        return
      end

      dice  = { d4: rand(250), d6: rand(500), d10: rand(750), d20: rand(1000) }
      total = Die.roll(dice.map { |die, count| "#{count}#{die}" })
      size  = get_bag_size(dice.values.inject(:+))

      m.reply "#{m.user.nick} rolls a #{size} bag of dice totalling " +
              "#{total}. " +
              score_check(m.user.nick.downcase, m.channel.name, total)
    end

    # Roll a specific set of dice and return the pretty result
    # @param [String] nick Nickname of the user rolling.
    # @param [String] dice Space delimited string of dice to role.
    #   (i.e. '6d12 4d20 d10'
    # @return [String] String describing the dice that were rolled
    def roll(m, dice = '1d20')
      result = Die.roll(dice.split(' '))

      result = "#{m.user.nick} rolls #{dice} totalling #{result}" if result.is_a?(Integer)
      m.reply result
    end

    # Simple method to return a flavor text 'size' description based on
    #   how many dice you happened to get in your dicebag roll.
    # @param [Fixnum] size The number of dice in the dicebag.
    # @return [String] Description of the size of the bag.
    def get_bag_size(size)
      case size
      when 0..100     then 'tiny'
      when 101..500   then 'small'
      when 501..1000  then 'medium'
      when 1001..1500 then 'large'
      when 1501..2000 then 'hefty'
      else 'huge'
      end
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
      "A new high score! Their old high roll was #{old[:score]}, " +
        "#{old[:time].ago.to_words}."
    end
  end
end
