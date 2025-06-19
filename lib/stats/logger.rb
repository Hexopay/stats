# frozen_string_literal: true

module Stats
  module Logger
    def log(message, level = :info)
      puts "#{Time.now}: #{Env.current} #{message&.truncate(100)}"
      Rails.logger.send(level, message)
    end

    def level(value: :nologs)
      @level ||= value
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
