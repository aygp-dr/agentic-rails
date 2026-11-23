module Telemetry
  # First in the Rack stack: every request gets a server span and every
  # response a traceparent (T1, T2, T8).
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      trace_id, parent = Traceparent.parse(env["HTTP_TRACEPARENT"])
      context = Context.new(
        trace_id: trace_id || Telemetry.trace_id, parent_span_id: parent,
        attributes: { "http.request.method" => env["REQUEST_METHOD"],
                      "url.path" => env["PATH_INFO"].presence || "/" }
                      .merge(Runner.attributes(baggage: env["HTTP_BAGGAGE"], query: env["QUERY_STRING"]))
      )
      env["telemetry.context"] = context
      Telemetry.current = context
      status = 500
      begin
        status, headers, body = @app.call(env)
        headers["traceparent"] = context.traceparent
        [status, headers, body]
      ensure
        Telemetry.current = nil
        route = route_template(env)
        context.set_attribute("http.route", route) if route
        Telemetry.write(context.finish(name: [env["REQUEST_METHOD"], route].compact.join(" "),
                                       status_code: status.to_i))
      end
    end

    private

    # "/pets/:id(.:format)" -> "/pets/:id", set by the Rails router (7.1+).
    def route_template(env)
      env["action_dispatch.route_uri_pattern"]&.delete_suffix("(.:format)")
    end
  end
end
