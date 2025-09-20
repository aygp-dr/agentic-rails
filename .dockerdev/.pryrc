# Pry configuration for Docker development

# Pretty print
require 'awesome_print'
AwesomePrint.pry!

# Command aliases
Pry.commands.alias_command 'c', 'continue'
Pry.commands.alias_command 's', 'step'
Pry.commands.alias_command 'n', 'next'
Pry.commands.alias_command 'f', 'finish'
Pry.commands.alias_command 'l', 'whereami'

# Rails helpers
if defined?(Rails)
  puts "Rails #{Rails.version} environment: #{Rails.env}"

  # Reload Rails
  def reload!
    puts "Reloading..."
    Rails.application.reload!
    true
  end

  # SQL query helper
  def sql(query)
    ActiveRecord::Base.connection.execute(query)
  end

  # Performance helper
  def benchmark(&block)
    time = Benchmark.realtime(&block)
    puts "Completed in #{(time * 1000).round(2)}ms"
  end
end

# History
Pry.config.history_file = "/usr/local/hist/.pry_history"

# Prompt
Pry.config.prompt_name = "agentic-rails"