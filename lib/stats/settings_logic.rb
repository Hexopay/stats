class SettingsLogic
  class << self
    attr_reader :source_hash, :name

    def source(path)
      @source_hash = YAML.load(File.open(path))
    end

    def namespace(name)
      @name = name
    end

    def load!
      source_hash[name].each do |k, v|
        create_method(self, k, v)
      end
    end

    def create_method(obj, k, v)
      obj.define_singleton_method k.to_sym do
        v
      end

      return unless v.is_a?(Hash)

      v.each do |kk, vv|
        create_method(v, kk, vv)
      end
    end
  end
end
