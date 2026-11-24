require "test_helper"

# slot.org T9, T10: a client span per statement, never a literal, and the
# statement itself carries its own span's traceparent.
class DbSpansTest < ActionDispatch::IntegrationTest
  include TelemetryHelpers

  SENTINEL = "zqxsentinel7731"
  COMMENT = %r{/\*traceparent='00-(\h{32})-(\h{16})-01'\*/\z}

  setup do
    @pet = Pet.create!(sku: "SKU-#{SENTINEL}", name: "Name-#{SENTINEL}", species: "dog",
                       price_cents: 4_242, stock: 3)
  end

  def capture_sql
    statements = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      statements << payload[:sql] unless payload[:cached]
    end
    yield
    statements
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "each statement is a client child span of the server span (T9)" do
    get "/pets.json", headers: { "baggage" => "app.driver=curl,app.run=db-1" }
    server = server_spans.sole
    children = spans.select { _1["kind"] == "client" }
    assert_not_empty children
    children.each do |child|
      assert_equal server["trace_id"], child["trace_id"]
      assert_equal server["span_id"], child["parent_span_id"]
      attributes = child["attributes"]
      assert_equal "sqlite", attributes["db.system.name"]
      assert_equal "curl", attributes["app.driver"]
      assert_not attributes.key?("app.run"), "the other runner keys stay on the server span"
    end
    select = children.find { _1.dig("attributes", "db.query.summary") == "SELECT pets" }
    assert select, children.map { _1["attributes"] }.inspect
    assert_equal "SELECT", select.dig("attributes", "db.operation.name")
    assert_equal "pets", select.dig("attributes", "db.collection.name")
    assert_equal "SELECT pets", select["name"]
  end

  # The sentinel goes only where the database sees it (bind values in WHERE
  # and INSERT), never in the URL: url.path is the request path by T8, so a
  # sku in /pets/:id is recorded there, by design, and the query string never is.
  test "no literal or bind value reaches traces.jsonl (T9)" do
    post "/cart/items", params: { sku: @pet.sku, quantity: 2 }
    post "/checkout", params: { idempotency_key: "key-#{SENTINEL}" }
    assert_response :redirect
    assert_operator spans.count { _1["kind"] == "client" }, :>=, 8
    assert spans.any? { _1.dig("attributes", "db.query.summary") == "INSERT orders" }
    text = File.read(traces_path)
    assert_not_includes text, SENTINEL
    # Ids and timestamps are random hex and nanosecond digits, which contain
    # "4242" by chance about one run in ten; the price can only leak elsewhere.
    generated = %w[trace_id span_id parent_span_id start_time_unix_nano end_time_unix_nano]
    spans.each { assert_not_includes _1.except(*generated).to_json, "4242" }
  end

  test "transaction and schema statements are not spans" do
    post "/cart/items", params: { sku: @pet.sku }
    summaries = spans.filter_map { _1.dig("attributes", "db.query.summary") }
    assert_includes summaries, "INSERT cart_items"
    summaries.each { assert_no_match(/\A(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE|PRAGMA)/, _1) }
  end

  test "the statement carries its own span's traceparent (T10)" do
    statements = capture_sql do
      get "/pets.json", headers: { "baggage" => "app.driver=curl" }
    end
    commented = statements.grep(COMMENT)
    assert_not_empty commented, statements.inspect
    children = spans.select { _1["kind"] == "client" }
    assert_equal commented.size, children.size, "one span per commented statement"
    commented.each do |sql|
      trace_id, span_id = sql.match(COMMENT).captures
      assert_equal response_trace_id, trace_id
      assert children.any? { _1["span_id"] == span_id }, "no client span #{span_id} for #{sql}"
    end
  end

  test "statements outside a request carry no comment and make no span" do
    statements = capture_sql { Pet.where(species: "dog").to_a }
    assert_not_empty statements
    statements.each { assert_no_match(/traceparent/, _1) }
    assert_empty spans
  end
end
