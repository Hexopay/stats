# frozen_string_literal: true

module Stats
  module Logger
    def log(message)
      puts "#{Time.now}: #{Env.current} #{message}\n"
    end

    # def loggable *meths
    #   meths.each do |m|

    #     define_method m do
    #       require 'pry'; binding.pry;
    #       puts 'start'
    #       send m
    #       puts 'end'
    #     end
    #   end
    #   require 'pry'; binding.pry;

    # end
  end
end
