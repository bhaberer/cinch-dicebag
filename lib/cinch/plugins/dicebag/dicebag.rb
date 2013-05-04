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

    self.help = "Roll a random bag of dice with .dicebag, you can also use .roll (dice count)d(sides) to roll specific dice (e.g. '.roll 4d6 3d20')"

    class Score < Struct.new(:nick, :score, :time)
      def to_yaml
        { :nick => nick, :score => score, :time => time }
      end
    end

    match /dicebag/,    method: :roll_bag
    match /roll (.*)/,  method: :roll_specific

    def initialize(*args)
      super
      @storage = CinchStorage.new(config[:filename] || 'yaml/dice.yml')
    end

    def roll_bag(m)
      if m.channel.nil?
        m.user.msg "You must use that command in the main channel."
        return
      end

      dice = { :d4 => rand(250), :d6 => rand(500), :d10 => rand(750), :d20 => rand(1000) }
      result = roll_dice(dice.map { |die, count| "#{count}#{die}" })

      total = dice.values.inject(:+)
      size =  case total
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

      m.reply "#{m.user.nick} rolls a #{size} bag of dice totalling #{result[:total]}."

      channel = m.channel.name
      nick    = m.user.nick.downcase

      unless @storage.data.key?(channel)
        @storage.data[channel] = Hash.new
      end

      unless @storage.data[channel].key?(nick)
        @storage.data[channel][nick] = { :score => result[:total], :time => Time.now }
      end

      if @storage.data[channel][nick][:score] < result[:total]
        old = @storage.data[channel][nick]
        @storage.data[channel][nick] = { :score => result[:total], :time => Time.now }

        m.reply "This is a new high score, their old score was #{old[:score]}, #{old[:time].ago.to_words}."
      end

      synchronize(:dice_save) do
        @storage.save
      end
    end

    def roll_specific(m, bag)
      result = roll_dice(bag.split(' '))
      if result.nil?
        m.reply "I'm sorry that's not the right way to roll dice.", true
      else
        m.reply "#{m.user.nick} rolls #{result[:rolls].join(', ')} totalling #{result[:total]}"
      end
    end

    private

    def roll_dice(dice)
      rolls = []
      total = 0

      # Clean out anything invalid
      dice.delete_if { |d| d.match(/\d+d\d+/).nil? }
      dice.each do |die|
        if die.match(/\d+d\d+/)
          count = die.match(/(\d+)d\d+/)[1].to_i rescue 0
          sides = die.match(/\d+d(\d+)/)[1].to_i rescue 0
        elsif die.match(/d\d+/)
          count = 1
          sides = die.match(/d(\d+)/)[1].to_i rescue 0
        end
        unless count.nil? || sides.nil?
          roll = roll_dice_type(sides, count)
          unless roll.nil?
            rolls << roll[:text]
            total += roll[:total]
          end
        end
      end
      if rolls.empty? || total.zero?
        return nil
      else
        return { :rolls => rolls, :total => total }
      end
    end

    def roll_dice_type(sides, count)
      unless sides < 1 || count < 1
        rolls = []
        count.times { rolls << rand(sides) + 1 }
        return {:total => rolls.inject(:+),
                :text => "#{count}d#{sides}" }
      end
    end
  end
end
