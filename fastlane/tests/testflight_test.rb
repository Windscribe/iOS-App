require "minitest/autorun"
require "yaml"

# Execute the real Fastfile; only external Fastlane actions are replaced.
class TestFlightLaneTest < Minitest::Test
  module UI
    def self.user_error!(message)
      raise message
    end
  end

  class LaneRunner
    UI = TestFlightLaneTest::UI
    attr_reader :calls, :lanes
    attr_accessor :missing_profile, :archive_failure

    def initialize
      @calls = []
      @lanes = {}
      file = File.expand_path("../Fastfile", __dir__)
      instance_eval(File.read(file), file)
    end

    def default_platform(_platform); end
    def desc(_description); end

    def lane(name, &block)
      @lanes[name] = block
    end

    def run(name)
      @lanes.fetch(name).call
    end

    def app_store_connect_api_key(**options)
      @calls << [:api_key, options]
    end

    def setup_ci
      @calls << [:setup_ci, {}]
    end

    def match(**options)
      @calls << [:match, options]
      suffix = options[:platform] == "tvos" ? "_tvos" : ""
      options[:app_identifier].each do |app_id|
        next if app_id == missing_profile
        ENV["sigh_#{app_id}_appstore#{suffix}_profile-name"] = "profile#{suffix}:#{app_id}"
      end
    end

    def update_code_signing_settings(**options)
      @calls << [:sign, options]
    end

    def gym(**options)
      @calls << [:gym, options]
      raise "Archive failed" if archive_failure
    end

    def latest_testflight_build_number(**options)
      @calls << [:latest_build, options]
      41
    end

    def upload_to_testflight(**options)
      @calls << [:upload, options]
    end
  end

  def setup
    @environment = ENV.to_h
    ENV.delete("BUILD_SCHEME")
    ENV.delete("CI_PIPELINE_IID")
    ENV["CI_COMMIT_REF_NAME"] = "main"
    ENV["UPLOAD_KEY"] = "" # No real credentials or external calls in these tests.
    ENV.keys.grep(/^sigh_/).each { |key| ENV.delete(key) }
    @runner = LaneRunner.new
  end

  def teardown
    ENV.replace(@environment)
  end

  def action(name)
    @runner.calls.find { |call, _| call == name }&.last
  end

  def run_lane(name)
    capture_io { @runner.run(name) }.first
  end

  def test_tv_release_uses_only_tv_profiles_and_explicit_export_mapping
    ENV["CI_PIPELINE_IID"] = "1234"
    output = run_lane(:tvTestFlight)
    match = action(:match)
    assert_equal "tvos", match[:platform]
    assert_equal "appstore", match[:type]
    assert_equal "gitlab_secure_files", match[:storage_mode]
    assert_equal true, match[:readonly]
    assert_equal %w[com.windscribe com.windscribe.PacketTunnel com.windscribe.WireGuardTunnel], match[:app_identifier]
    signing = @runner.calls.select { |name, _| name == :sign }.map(&:last)
    assert_equal %w[WindscribeTV PacketTunnel WireGuardTunnel], signing.flat_map { |options| options[:targets] }
    assert signing.all? { |options| options[:use_automatic_signing] == false }
    assert signing.all? { |options| options[:profile_name].start_with?("profile_tvos:") }
    gym = action(:gym)
    assert_equal "WindscribeTV-Release", gym[:scheme]
    assert_equal "appletvos", gym[:sdk]
    assert_equal "generic/platform=tvOS", gym[:destination]
    assert_equal "manual", gym[:export_options][:signingStyle]
    assert_equal false, gym[:export_options][:manageAppVersionAndBuildNumber]
    assert_equal match[:app_identifier].to_h { |id| [id, "profile_tvos:#{id}"] }, gym[:export_options][:provisioningProfiles]
    assert_includes gym[:xcargs], "CURRENT_PROJECT_VERSION=1234"
    assert_includes gym[:xcargs], "MARKETING_VERSION=#{@runner.tv_marketing_version}"
    refute_includes gym[:xcargs], "WS_INTERNAL_FLAG="
    assert_nil action(:latest_build)
    assert_equal({ app_identifier: "com.windscribe", app_platform: "appletvos", skip_waiting_for_build_processing: true, distribute_external: false }, action(:upload))
    assert_includes output, "[DEPLOY_TVOS_INFO] version=#{@runner.tv_marketing_version} build=1234"
    refute_includes output, "[DEPLOY_INFO]"
    assert_operator @runner.calls.index { |name, _| name == :gym }, :<, @runner.calls.index { |name, _| name == :upload }
  end

  def test_tv_staging_selects_staging_scheme
    ENV["BUILD_SCHEME"] = "WindscribeTV-Staging"
    ENV["CI_PIPELINE_IID"] = "1234"
    run_lane(:tvTestFlight)
    assert_equal "WindscribeTV-Staging", action(:gym)[:scheme]
    assert_equal "tvos", action(:match)[:platform]
  end

  def test_tv_local_build_number_queries_tv_version_not_ios
    run_lane(:tvTestFlight)
    assert_equal({ app_identifier: "com.windscribe", platform: "appletvos", version: @runner.tv_marketing_version, initial_build_number: 1 }, action(:latest_build))
    assert_includes action(:gym)[:xcargs], "CURRENT_PROJECT_VERSION=42"
  end

  def test_release_branch_preserves_existing_internal_flag_policy
    ENV["CI_COMMIT_REF_NAME"] = "release-branch-tv"
    run_lane(:tvTestFlight)
    assert_includes action(:gym)[:xcargs], "WS_INTERNAL_FLAG="
    assert_includes action(:gym)[:xcargs], "WS_APP_ICON=AppIcon"
  end

  def test_tv_rejects_ios_or_debug_schemes_before_any_external_action
    ["Windscribe-Release", "WindscribeTV-Debug"].each do |scheme|
      ENV["BUILD_SCHEME"] = scheme
      assert_raises(RuntimeError) { run_lane(:tvTestFlight) }
      assert_empty @runner.calls
    end
  end

  def test_missing_tv_profile_does_not_fall_back_to_ios_profile
    @runner.missing_profile = "com.windscribe.PacketTunnel"
    ENV["sigh_com.windscribe.PacketTunnel_appstore_profile-name"] = "ios-only-profile"
    error = assert_raises(RuntimeError) { run_lane(:tvTestFlight) }
    assert_includes error.message, "Missing tvos App Store profile for com.windscribe.PacketTunnel"
    assert_nil action(:gym)
    assert_nil action(:upload)
  end

  def test_archive_failure_prevents_upload_and_success_marker
    @runner.archive_failure = true
    output = capture_io do
      assert_raises(RuntimeError) { @runner.run(:tvTestFlight) }
    end.first
    assert_nil action(:upload)
    refute_includes output, "[DEPLOY_TVOS_INFO]"
  end

  def test_ios_release_and_staging_keep_existing_signing_and_upload_behavior
    ["Windscribe-Release", "Windscribe-Staging"].each do |scheme|
      @runner = LaneRunner.new
      ENV["BUILD_SCHEME"] = scheme
      ENV["CI_PIPELINE_IID"] = "1234"
      output = run_lane(:iOSTestFlight)
      assert_equal "ios", action(:match)[:platform]
      assert_equal %w[com.windscribe com.windscribe.PacketTunnel com.windscribe.WireGuardTunnel com.windscribe.SiriIntents com.windscribe.HomeWidget], action(:match)[:app_identifier]
      signing = @runner.calls.select { |name, _| name == :sign }.map(&:last)
      assert_equal %w[Windscribe PacketTunnel WireGuardTunnel SiriIntents HomeWidgetExtension], signing.flat_map { |options| options[:targets] }
      assert signing.all? { |options| options[:profile_name].start_with?("profile:") }
      assert_equal scheme, action(:gym)[:scheme]
      assert_equal "./exportOptions.plist", action(:gym)[:export_options]
      assert_equal "CURRENT_PROJECT_VERSION=1234", action(:gym)[:xcargs]
      refute action(:gym).key?(:sdk)
      refute action(:gym).key?(:destination)
      assert_equal({ skip_waiting_for_build_processing: true, distribute_external: false }, action(:upload))
      assert_includes output, "[DEPLOY_INFO]"
    end
  end

  def test_unsigned_mr_builds_remain_unsigned_without_uploads
    { iOSBuild: "Windscribe-Debug", tvBuild: "WindscribeTV-Debug" }.each do |lane, scheme|
      @runner = LaneRunner.new
      run_lane(lane)
      assert_equal scheme, action(:gym)[:scheme]
      assert_equal true, action(:gym)[:skip_codesigning]
      assert_equal true, action(:gym)[:skip_archive]
      assert_nil action(:match)
      assert_nil action(:upload)
    end
  end

  def test_tv_ci_jobs_are_manual_and_excluded_from_mrs
    ci = YAML.load_file(File.expand_path("../../.gitlab-ci.yml", __dir__))
    base = ci.fetch(".deploy-tvos-base")
    assert_equal ["fastlane tvTestFlight"], base["script"]
    assert_equal [{ "if" => "$CI_MERGE_REQUEST_ID", "when" => "never" }, { "when" => "manual" }], base["rules"]
    assert_equal true, base["allow_failure"]
    %w[Release Staging].each do |variant|
      job = ci.fetch("Deploy-tvOS-#{variant}")
      assert_equal ".deploy-tvos-base", job["extends"]
      assert_equal "WindscribeTV-#{variant}", job.fetch("variables").fetch("BUILD_SCHEME")
    end
    assert_includes ci.fetch("LintCheck").fetch("script"), "ruby fastlane/tests/testflight_test.rb"
  end
end
