require "test_helper"

# Chrome DevTools automatic workspace folders (Chromium
# docs/ecosystem/automatic_workspace_folders.md): the server names the checkout
# it serves, so Sources > Workspace maps to the right directory, per slot.
class DevtoolsWorkspaceTest < ActionDispatch::IntegrationTest
  PATH = "/.well-known/appspecific/com.chrome.devtools.json".freeze

  test "the payload is the checkout's real path and a UUID stable for that path" do
    a = Api::DevController.devtools_workspace(Rails.root)
    assert_equal Rails.root.realpath.to_s, a[:workspace][:root]
    assert_match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/, a[:workspace][:uuid])
    assert_equal a, Api::DevController.devtools_workspace(Rails.root)
  end

  test "two checkouts get two UUIDs" do
    Dir.mktmpdir do |other|
      refute_equal Api::DevController.devtools_workspace(Rails.root)[:workspace][:uuid],
                   Api::DevController.devtools_workspace(other)[:workspace][:uuid]
    end
  end

  test "outside development it reveals no path" do
    get PATH
    assert_response :no_content
    assert_empty response.body
  end
end
