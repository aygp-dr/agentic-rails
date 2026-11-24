require "yaml"

module Flags
  # The registry of slot.org G1: name, stage (a..e), default (off until d), routes, owner, since.
  class Registry
    class Invalid < StandardError; end

    Entry = Struct.new(:name, :stage, :default, :routes, :owner, :since, keyword_init: true) do
      def default_on? = default == "on"
    end

    NAME = /\A[a-z0-9-]+\z/
    STAGES = %w[a b c d e].freeze

    def self.load(path = Rails.root.join("config/flags.yml"))
      new(YAML.safe_load_file(path) || [])
    end

    def initialize(entries)
      @entries = entries.to_h do |raw|
        entry = Entry.new(name: raw["name"].to_s, stage: raw["stage"].to_s, default: raw["default"].to_s,
                          routes: Array(raw["routes"]), owner: raw["owner"], since: raw["since"])
        validate!(entry)
        [entry.name, entry]
      end
    end

    def names = @entries.keys
    def fetch(name) = @entries.fetch(name.to_s)
    def include?(name) = @entries.key?(name.to_s)

    private

    def validate!(entry)
      raise Invalid, "flag name #{entry.name.inspect} is not [a-z0-9-]" unless entry.name.match?(NAME)
      raise Invalid, "#{entry.name}: stage #{entry.stage.inspect} is not a..e" unless STAGES.include?(entry.stage)
      raise Invalid, "#{entry.name}: default #{entry.default.inspect} is not on or off" unless %w[on off].include?(entry.default)
      return unless entry.default_on? && entry.stage < "d"

      raise Invalid, "#{entry.name}: default on before stage d"
    end
  end
end
