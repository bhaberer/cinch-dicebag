module Cinch
  module Plugins
    class Dicebag
      # Class to handle rolling of a preset bag of dice.
      class Bag
        attr_accessor :count, :dice, :score

        # Create a new bag
        # @param [Hash] dice_hash Hash of dice, in the format of
        #   { :num_sides => :max_dice_to_roll, ... }
        #   The bag will randomly roll (1-:max_dice_to_roll) :num_sided dice.
        def initialize(dice_hash)
          fail unless good_hash?(dice_hash)
          @dice = dice_hash
          @count = 0
          @score = 0
        end

        def stats
          max_score = @dice.keys.inject(0) { |sum, x| sum + (x * @dice[x]) }
          min_score = @dice.keys.count
          max_count = @dice.values.inject(0) { |sum, x| sum + x }
          min_count = @dice.keys.count
          { min_count: min_count, max_count: max_count,
            min_score: min_score, max_score: max_score }
        end

        # Roll the bag of dice, this will roll the dice and update the current
        #   score and count
        def roll
          dice = die_array
          @score = Die.roll(dice)
          @count = dice.map { |d| d[/(\d+)d\d+/, 1].to_i || 1 }.inject(0, :+)
          return self
        end

        # Simple method to return a flavor text 'size' description based on
        #   how many dice you happened to get in your dicebag roll.
        # @param [Fixnum] size The number of dice in the dicebag.
        # @return [String] Description of the size of the bag.
        def size
          case
          when @count < 1000 then 'tiny'
          when @count < 2000 then 'small'
          when @count < 3000 then 'medium'
          when @count < 4000 then 'large'
          when @count < 5000 then 'hefty'
          else 'massive'
          end
        end

        private

        # Check to make sure that the passed hash of dice looks basically
        #   reasonable.
        # e.g. { 4 => 10, 6 => 20, 100 => 20 }
        def good_hash?(dice_hash)
          dice_hash.keys { |k| return false unless k.is_a?(Integer) }
          dice_hash.values { |k| return false unless k.is_a?(Integer) }
          true
        end

        # Render the @dice hash as an array of rolls to pass to the Die module.
        #   This also is where we randomly select how many dice from the range
        #   are actually rolled.
        def die_array
          @dice.keys.map do |sides|
            "#{rand(@dice[sides] + 1)}d#{sides}"
          end
        end
      end
    end
  end
end
