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

    # Chrome DevTools automatic workspace folder: the checkout this process
    # serves (a slot's worktree, once there are slots), with a UUID derived
    # from that path so it is stable across restarts and differs per checkout.
    def workspace
      render json: self.class.devtools_workspace(Rails.root)
    end

    def self.devtools_workspace(root)
      path = Pathname(root).realpath.to_s
      { workspace: { root: path, uuid: Digest::UUID.uuid_v5(Digest::UUID::URL_NAMESPACE, "file://#{path}") } }
    end

    private

    def git(*args)
      out, status = Open3.capture2("git", "--no-optional-locks", *args, chdir: Rails.root.to_s, err: File::NULL)
      status.success? ? out.strip : nil
    end
  end
end
