# Database client spans and the sqlcommenter traceparent (slot.org T9, T10);
# see lib/telemetry/sql.rb. The request middleware is in config/application.rb.
ActiveSupport.on_load(:active_record) { Telemetry::Sql.install }
