# frozen_string_literal: true

module Stats
  class Logger
    def error(message)
      puts "#{Time.now}: #{Env.current} #{message}\n"
    end
  end
end
