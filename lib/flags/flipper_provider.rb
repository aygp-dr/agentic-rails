module Flags
  # An OpenFeature provider backed by Flipper (none is published for Ruby). The mapping:
  #   OpenFeature flag key            -> Flipper feature, and a registry entry
  #   evaluation context targeting_key -> Flipper actor (flipper_id)
  #   reason STATIC                   -> Flipper's boolean gate is set
  #   reason TARGETING_MATCH          -> an actor (or other non-boolean) gate matched
  #   reason DEFAULT                  -> no gate matched: the registry default
  #   variant "on" / "off"            -> the registry's path (slot.org G5 <p>.ff.path)
  # Booleans only: a sorry-start flag is on or off.
  class FlipperProvider
    Reason = OpenFeature::SDK::Provider::Reason
    ErrorCode = OpenFeature::SDK::Provider::ErrorCode
    Details = OpenFeature::SDK::Provider::ResolutionDetails
    Actor = Struct.new(:flipper_id)

    attr_reader :metadata

    def initialize(flipper:, registry:)
      @flipper = flipper
      @registry = registry
      @metadata = OpenFeature::SDK::Provider::ProviderMetadata.new(name: "Flipper (agentic-rails)").freeze
    end

    def init(_evaluation_context = nil); end
    def shutdown; end

    def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
      return Details.new(value: default_value, reason: Reason::ERROR, error_code: ErrorCode::FLAG_NOT_FOUND) unless @registry.include?(flag_key)

      entry = @registry.fetch(flag_key)
      feature = @flipper.feature(flag_key)
      # Flipper stores a disabled feature as an untouched one that exists: exist? tells them apart.
      return resolved(entry.default_on?, Reason::DEFAULT) unless feature.exist?

      case feature.state
      when :on then resolved(true, Reason::STATIC)
      when :off then resolved(false, Reason::STATIC)
      else
        key = evaluation_context&.targeting_key
        return resolved(true, Reason::TARGETING_MATCH) if key && feature.enabled?(Actor.new(key))

        resolved(entry.default_on?, Reason::DEFAULT)
      end
    end

    %i[string number integer float object].each do |type|
      define_method(:"fetch_#{type}_value") do |flag_key:, default_value:, evaluation_context: nil|
        Details.new(value: default_value, reason: Reason::ERROR, error_code: ErrorCode::TYPE_MISMATCH,
                    error_message: "#{flag_key}: flags here are boolean")
      end
    end

    private

    def resolved(value, reason) = Details.new(value:, reason:, variant: value ? "on" : "off")
  end
end
