module Stats
  module Utils
    def root
      File.expand_path File.join(File.dirname(__FILE__), '../..')
    end

    def env
      @env ||= ENV['RACK_ENV'] || 'development'
    end
  end
end
