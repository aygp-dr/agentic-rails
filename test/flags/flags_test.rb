require "test_helper"

# One flag, three vocabularies: the registry (slot.org G1: flag, stage, default, path),
# Flipper (feature, gate, actor) and OpenFeature (flag key, evaluation context, reason, variant).
# The provider maps Flipper's state into OpenFeature's resolution; these tests pin the mapping.
class FlagsTest < ActiveSupport::TestCase
  Actor = Struct.new(:flipper_id)

  setup do
    @flipper = Flipper.new(Flipper::Adapters::Memory.new)
    @registry = Flags::Registry.new([
      { "name" => "probe", "stage" => "a", "default" => "off", "routes" => [], "owner" => "tests", "since" => "2026-11-24" },
      { "name" => "lit", "stage" => "d", "default" => "on", "routes" => ["/"], "owner" => "tests", "since" => "2026-11-24" }
    ])
    @provider = Flags::FlipperProvider.new(flipper: @flipper, registry: @registry)
    @client = OpenFeature::SDK::Client.new(provider: @provider)
  end

  def details(key, context = nil)
    @client.fetch_boolean_details(flag_key: key, default_value: false, evaluation_context: context)
  end

  test "the shipped registry is valid and has only the test-only probe flag" do
    registry = Flags::Registry.load
    assert_equal ["probe"], registry.names
    assert_equal "off", registry.fetch("probe").default
  end

  test "registry rejects a bad name, stage, or a default on before stage d" do
    bad = [
      { "name" => "Probe", "stage" => "a", "default" => "off" },
      { "name" => "probe", "stage" => "f", "default" => "off" },
      { "name" => "probe", "stage" => "b", "default" => "on" }
    ]
    bad.each { |entry| assert_raises(Flags::Registry::Invalid) { Flags::Registry.new([entry]) } }
  end

  test "an untouched Flipper feature resolves to the registry default" do
    probe = details("probe")
    assert_equal false, probe.value
    assert_equal "off", probe.variant
    assert_equal OpenFeature::SDK::Provider::Reason::DEFAULT, probe.reason

    lit = details("lit")
    assert_equal true, lit.value
    assert_equal "on", lit.variant
  end

  test "Flipper's boolean gate is OpenFeature's static resolution" do
    @flipper.enable(:probe)
    probe = details("probe")
    assert_equal [true, "on", OpenFeature::SDK::Provider::Reason::STATIC], [probe.value, probe.variant, probe.reason]

    @flipper.disable(:lit)
    assert_equal false, details("lit").value
  end

  test "Flipper's actor gate is OpenFeature's targeting match on targeting_key" do
    @flipper.enable_actor(:probe, Actor.new("session-1"))
    hit = details("probe", OpenFeature::SDK::EvaluationContext.new(targeting_key: "session-1"))
    miss = details("probe", OpenFeature::SDK::EvaluationContext.new(targeting_key: "session-2"))
    assert_equal [true, OpenFeature::SDK::Provider::Reason::TARGETING_MATCH], [hit.value, hit.reason]
    assert_equal [false, OpenFeature::SDK::Provider::Reason::DEFAULT], [miss.value, miss.reason]
  end

  test "a flag outside the registry is not found, whatever Flipper holds" do
    @flipper.enable(:stray)
    stray = details("stray")
    assert_equal false, stray.value
    assert_equal OpenFeature::SDK::Provider::ErrorCode::FLAG_NOT_FOUND, stray.error_code
  end

  test "the app's OpenFeature provider is the Flipper one" do
    assert_kind_of Flags::FlipperProvider, OpenFeature::SDK.provider
  end
end
