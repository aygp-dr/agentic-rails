require "open3"

# Tool endpoints for development only: they describe the checkout, so they
# answer 204 (no body, no console error) outside development.
module Api
  class DevController < ApplicationController
    before_action { head :no_content unless Rails.env.development? }

    def build
      render json: {
        sha: git("rev-parse", "--short", "HEAD"),
        dirty: !git("status", "--porcelain", "--untracked-files=no").to_s.empty?,
        branch: ENV["APP_BRANCH"].presence || git("rev-parse", "--abbrev-ref", "HEAD"),
        slot: ENV["APP_SLOT"]&.then { Integer(_1, exception: false) },
        port: request.port,
        env: Rails.env
      }
    end

    private

    def git(*args)
      out, status = Open3.capture2("git", "--no-optional-locks", *args, chdir: Rails.root.to_s, err: File::NULL)
      status.success? ? out.strip : nil
    end
  end
end
