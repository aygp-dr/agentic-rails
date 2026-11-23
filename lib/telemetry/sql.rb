module Telemetry
  # Database statements (T9, T10). Two halves joined by the comment itself:
  # the query transformer runs before the statement is sent, picks the
  # statement's span id and appends /*traceparent='00-<trace>-<span>-01'*/
  # (sqlcommenter); the sql.active_record subscriber sees the same text after
  # it ran and turns it into a client span with that id. A statement with no
  # comment makes no span, so a span exists exactly when its statement
  # carried the trace.
  #
  # Not spans (and not commented): statements outside a request (boot,
  # migrations, seeds, the console: they'd have no parent, an R2 problem),
  # transaction control (BEGIN, COMMIT, ROLLBACK, SAVEPOINT, RELEASE), PRAGMA
  # and sqlite_master/sqlite_schema introspection, and query-cache hits
  # (nothing reached the database).
  module Sql
    COMMENT = %r{\s*/\*traceparent='00-(\h{32})-(\h{16})-01'\*/\z}
    NOISE = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE|PRAGMA|END)\b|\bsqlite_(master|schema|temp_master)\b/i
    COLLECTION = /\b(?:FROM|INTO|UPDATE|JOIN)\s+["`\[]?([A-Za-z_][A-Za-z0-9_]*)/i

    # ActiveRecord.query_transformers: called with (sql, connection).
    module Commenter
      def self.call(sql, _connection)
        context = Telemetry.current
        return sql if context.nil? || sql.match?(NOISE) || sql.match?(COMMENT)
        "#{sql.sub(/;\s*\z/, "")} /*traceparent='#{Traceparent.format(context.trace_id, Telemetry.span_id)}'*/"
      end
    end

    # ActiveSupport::Notifications subscriber for sql.active_record.
    module Subscriber
      def self.call(event)
        payload = event.payload
        context = Telemetry.current
        return if context.nil? || payload[:cached]
        match = COMMENT.match(payload[:sql].to_s) or return
        trace_id, span_id = match.captures
        return unless trace_id == context.trace_id
        end_ns = Telemetry.now_ns
        attributes = Sql.attributes(payload[:sql].sub(COMMENT, ""))
        context.add_client_span(span_id: span_id, name: attributes["db.query.summary"],
                                start_ns: end_ns - (event.duration * 1_000_000).round, end_ns: end_ns,
                                attributes: attributes)
      end
    end

    # Operation and table only: never the statement text, so no literal or
    # bind value can reach a span.
    def self.attributes(sql)
      operation = sql[/\A\s*(?:WITH\b.*?\)\s*)?([A-Za-z]+)/m, 1].to_s.upcase
      collection = sql[COLLECTION, 1]
      attributes = { "db.system.name" => "sqlite", "db.operation.name" => operation }
      attributes["db.collection.name"] = collection if collection
      attributes["db.query.summary"] = [operation, collection].compact.join(" ")
      attributes
    end

    def self.install
      ActiveRecord.query_transformers << Commenter unless ActiveRecord.query_transformers.include?(Commenter)
      @subscription ||= ActiveSupport::Notifications.subscribe("sql.active_record") { Subscriber.call(_1) }
    end
  end
end
