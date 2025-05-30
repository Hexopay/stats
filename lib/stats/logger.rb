# frozen_string_literal: true

module Stats
  module Logger
    def log(message)
      return if Env.production?

      puts "#{Time.now}: #{Env.current} #{message}\n"
    end

    # def loggable *meths, *opts
    #   meths.each do |m|
    #     define_method m do
    #       puts 'start'
    #       send m
    #       puts 'end'
    #     end
    #   end
    # end
  end
end
