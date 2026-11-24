# Flipper holds flag overrides (memory adapter: nothing persists across restarts yet, and nothing is
# written to the state dir); OpenFeature is the API the app evaluates through. No route reads a flag yet.
Rails.application.config.to_prepare do
  OpenFeature::SDK.configure do |config|
    config.set_provider(Flags::FlipperProvider.new(flipper: Flipper.instance, registry: Flags::Registry.load))
  end
end
