module Cinch
  module Plugins
    class Dicebag
      # Class to handle rolling of a preset bag of dice.
      class Bag
        attr_accessor :count, :dice, :score
        def initialize(dice_hash)
          fail unless good_hash?(dice_hash)
          @dice = dice_hash
          @count = 0
          @score = 0
        end

        def roll
          dice = die_array
          @score = Die.roll(dice)
          @count = dice.map { |d| d[/(\d+)d\d+/, 1].to_i || 1 }.inject(0, :+)
        end

        def good_hash?(dice_hash)
          dice_hash.keys { |k| return false unless k.is_a?(Integer) }
          dice_hash.values { |k| return false unless k.is_a?(Integer) }
          true
        end

        # Simple method to return a flavor text 'size' description based on
        #   how many dice you happened to get in your dicebag roll.
        # @param [Fixnum] size The number of dice in the dicebag.
        # @return [String] Description of the size of the bag.
        def size
          case @count
          when 0..1000 then 'tiny'
          when 1001..1500 then 'small'
          when 1501..2500 then 'medium'
          when 2501..3500 then 'large'
          when 3501..4500 then 'hefty'
          else 'massive'
          end
        end

        private

        def die_array
          @dice.keys.map do |sides|
            "#{rand(@dice[sides])}d#{sides}"
          end
        end
      end
    end
  end
end
