require "test_helper"
require "open3"

# bin/report (slot.org R1-R3) on fixture files: each problem kind exits 1, so
# does an empty window, and a clean window prints its counts and exits 0.
class ReportTest < ActiveSupport::TestCase
  FIXTURES = Rails.root.join("test/fixtures/files/report")
  T0_MS = 1_763_900_000_000 # the fixtures' first span starts here

  def report(fixture, *args)
    Dir.mktmpdir("report") do |dir|
      FileUtils.cp(FIXTURES.join("#{fixture}.jsonl"), File.join(dir, "traces.jsonl")) if fixture
      out, err, status = Open3.capture3(RbConfig.ruby, Rails.root.join("bin/report").to_s, "--data", dir, *args,
                                        stdin_data: "")
      [out + err, status.exitstatus]
    end
  end

  test "a clean window prints traces, spans, drivers and runs, and exits 0 (R1)" do
    out, code = report("clean", "--since", "0")
    assert_equal 0, code, out
    assert_match(/^traces\s+2$/, out)
    assert_match(/^spans\s+3$/, out)
    assert_match(/^\s+curl\s+2$/, out)
    assert_match(/^\s+playwright\s+1$/, out)
    assert_match(/^\s+r-1\s+2$/, out, "a run counts every span of its traces")
    assert_match(/^\s+pw-1\s+1$/, out)
    assert_match(/^problems\s+0$/, out)
  end

  test "--since is epoch milliseconds and filters by span start (R1)" do
    out, code = report("clean", "--since", (T0_MS + 30_000).to_s)
    assert_equal 0, code, out
    assert_match(/^traces\s+1$/, out)
    assert_match(/^\s+playwright\s+1$/, out)
    assert_no_match(/curl/, out)
  end

  test "a parent that started before the window is not missing (R2, 0.1.1)" do
    out, code = report("clean", "--since", (T0_MS + 1).to_s)
    assert_equal 0, code, out
    assert_match(/^spans\s+2$/, out)
  end

  {
    "server_error" => /server-error/,
    "no_driver" => /span-without-driver/,
    "two_drivers" => /trace-with-two-drivers/,
    "missing_parent" => /missing-parent/,
    "not_json" => /not-json/
  }.each do |fixture, kind|
    test "#{fixture} is a problem and exits 1 (R2, R3)" do
      out, code = report(fixture, "--since", "0")
      assert_equal 1, code, out
      assert_match kind, out
      assert_match(/^problems\s+[1-9]/, out)
    end
  end

  test "a window with no traces exits 1 (R3)" do
    out, code = report("clean", "--since", (T0_MS + 3_600_000).to_s)
    assert_equal 1, code, out
    assert_match(/^traces\s+0$/, out)
    assert_match(/no traces/, out)
  end

  test "a data dir with no traces.jsonl exits 1 and names the path (R3)" do
    out, code = report(nil, "--since", "0")
    assert_equal 1, code, out
    assert_match(/traces\.jsonl/, out)
  end

  test "--minutes N is the last N minutes; bad arguments exit 2" do
    _, code = report("clean", "--minutes", "5")
    assert_equal 1, code, "the fixtures are from 2025, outside the last five minutes"
    _, code = report("clean", "--since", "yesterday")
    assert_equal 2, code
    _, code = report("clean", "--bogus")
    assert_equal 2, code
  end
end
