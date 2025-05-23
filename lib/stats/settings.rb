# frozen_string_literal: true

require_relative 'settings_logic'
require_relative 'utils'

module Stats
  extend Stats::Utils

  class Settings < SettingsLogic
    def self.setup!
      source "#{::Stats.root}/config/settings.yml"
      namespace Env.current
      load!
    end
  end
end
