# -*- coding: utf-8 -*-
require 'cinch'
require 'cinch-toolbox'
require 'cinch-cooldown'
require 'cinch-storage'
require 'time-lord'

module Cinch::Plugins
  class Dicebag
    include Cinch::Plugin

    enforce_cooldown

    attr_accessor :storage

    self.help = "Roll a random bag of dice with .dicebag, you can also use .roll (dice count)d(sides) to roll specific dice (e.g. '.roll 4d6 3d20')"

    match /dicebag/
    match /roll (.*)/

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/dice.yml')
    end

    def execute(m, dice = nil)
      m.reply (dice.nil? ? roll_dicebag(m.user.nick, m.channel) : roll(m.user.nick, dice))
    end

    def roll_dicebag(nick, channel)
      return "You must use that command in the main channel." if channel.nil?

      dice  = { :d4 => rand(250), :d6 => rand(500), :d10 => rand(750), :d20 => rand(1000) }

      total = roll_dice(dice.map { |die, count| "#{count}#{die}" })
      size  = get_bag_size(dice.values.inject(:+))

      message = "#{nick} rolls a #{size} bag of dice totalling #{total}. " +
                score_check(nick.downcase, channel.name, total)

      return message
    end

    def roll(nick, dice)
      return nil if dice.nil? || nick.nil?

      result = roll_dice(dice.split(' '))

      return "#{nick} rolls #{dice} totalling #{result}" unless result.nil?
    end

    def roll_die(sides, count)
      return 0 if sides < 1 || count < 1
      total = 0
      count.times { total += rand(sides) + 1 }
      return total
    end

    def roll_dice(dice)
      # Clean out anything invalid
      dice.delete_if { |d| d.match(/\d*d\d+/).nil? }

      total = 0

      # Roll each group and total up the returned value
      dice.each do |die|
        count = die[/(\d+)d\d+/, 1] || 1
        sides = die[/\d?d(\d+)/, 1]
        unless count.nil? || sides.nil?
          total += roll_die(sides.to_i, count.to_i)
        end
      end

      return total
    end

    def get_bag_size(size)
      case size
      when 0..100
        'tiny'
      when 101..500
        'small'
      when 501..1000
        'medium'
      when 1001..1500
        'large'
      when 1501..2000
        'hefty'
      else
        'huge'
      end
    end

    def score_check(nick, channel, score)
      # If the chennel or nick are not already initialized, spin them up
      @storage.data[channel] ||= Hash.new
      @storage.data[channel][nick] ||= { :score => score, :time => Time.now }

      # Check and see if this is a higher score.
      old = @storage.data[channel][nick]
      if @storage.data[channel][nick][:score] < score
        @storage.data[channel][nick] = { :score => score, :time => Time.now }
        @storage.synced_save(@bot)
        return "A new high score! Their old high roll was #{old[:score]}, #{old[:time].ago.to_words}."
      else
        return ''
      end
    end
  end
end
