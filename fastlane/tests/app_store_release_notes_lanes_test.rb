require "minitest/autorun"
require "yaml"

# Execute the actual Fastfile and updater, replacing only Apple/Fastlane boundaries.
class AppStoreReleaseNotesLanesTest < Minitest::Test
  module UI
    class << self
      attr_accessor :messages

      def user_error!(message)
        raise message
      end

      def success(message)
        messages << message
      end
    end
  end

  module Spaceship
    module ConnectAPI
      module Platform
        IOS = "IOS"
        TV_OS = "TV_OS"
      end

      class App
        class << self
          attr_accessor :instance, :lookups

          def find(identifier)
            lookups << identifier
            instance
          end
        end
      end
    end
  end

  class Localization
    attr_reader :locale, :updates, :whats_new
    attr_accessor :ignore_update, :update_error

    def initialize(locale, whats_new = "Old notes")
      @locale = locale
      @whats_new = whats_new
      @updates = []
    end

    def update(attributes:)
      raise update_error if update_error
      @updates << attributes
      @whats_new = attributes.fetch("whats_new") unless ignore_update
    end
  end

  class Version
    attr_reader :version_string, :localizations, :reads

    def initialize(version_string, localizations)
      @version_string = version_string
      @localizations = localizations
      @reads = 0
    end

    def get_app_store_version_localizations
      @reads += 1
      @localizations
    end
  end

  class App
    attr_reader :platforms
    attr_accessor :versions

    def initialize(versions)
      @versions = versions
      @platforms = []
    end

    def get_edit_app_store_version(platform:)
      @platforms << platform
      @versions[platform]
    end
  end

  class LaneRunner
    UI = AppStoreReleaseNotesLanesTest::UI
    Spaceship = AppStoreReleaseNotesLanesTest::Spaceship
    attr_reader :auth_calls

    def initialize
      @lanes = {}
      @auth_calls = 0
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

    def app_store_connect_api_key(**_options)
      @auth_calls += 1
    end
  end

  def setup
    @environment = ENV.to_h
    ENV["APP_VERSION"] = "1.0.5"
    ENV["RELEASE_NOTES"] = "First line\\nSecond line"
    ENV["UPLOAD_KEY"] = "" # Tests never use credentials or make external calls.
    # Identical version strings must not allow either lane to touch the other platform.
    @ios = Version.new("1.0.5", [Localization.new("en-US")])
    @tv = Version.new("1.0.5", [Localization.new("fr-FR"), Localization.new("en-US")])
    @app = App.new("IOS" => @ios, "TV_OS" => @tv)
    Spaceship::ConnectAPI::App.instance = @app
    Spaceship::ConnectAPI::App.lookups = []
    UI.messages = []
    @runner = LaneRunner.new
  end

  def teardown
    ENV.replace(@environment)
  end

  def test_tv_lane_updates_only_tv_localizations_and_reads_them_back
    @runner.run(:updateTVAppStoreReleaseNotes)
    assert_equal ["com.windscribe"], Spaceship::ConnectAPI::App.lookups
    assert_equal ["TV_OS"], @app.platforms
    assert_equal 1, @runner.auth_calls
    @tv.localizations.each do |localization|
      assert_equal [{ "whats_new" => "First line\nSecond line" }], localization.updates
    end
    assert_equal 2, @tv.reads
    assert_equal 0, @ios.reads
    assert_empty @ios.localizations.first.updates
    assert_equal ["Updated and verified release notes for: en-US, fr-FR"], UI.messages
  end

  def test_existing_ios_lane_never_touches_tv
    @runner.run(:updateAppStoreReleaseNotes)
    assert_equal ["IOS"], @app.platforms
    assert_equal [{ "whats_new" => "First line\nSecond line" }], @ios.localizations.first.updates
    assert_equal 2, @ios.reads
    assert_equal 0, @tv.reads
    assert @tv.localizations.all? { |localization| localization.updates.empty? }
  end

  def test_rerun_skips_matching_notes_and_still_verifies
    @runner.run(:updateTVAppStoreReleaseNotes)
    @runner.run(:updateTVAppStoreReleaseNotes)
    assert @tv.localizations.all? { |localization| localization.updates.size == 1 }
    assert_equal 4, @tv.reads
    assert_equal "Release notes already match App Store Connect for all locales", UI.messages.last
  end

  def test_wrong_version_fails_before_any_localization_write
    ENV["APP_VERSION"] = "1.0.6"
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_includes error.message, "1.0.5, not 1.0.6"
    assert_equal 0, @tv.reads
    assert_empty UI.messages
  end

  def test_no_editable_tv_version_does_not_fall_back_to_ios
    @app.versions.delete("TV_OS")
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_equal "Could not find an editable TV_OS version", error.message
    assert_equal ["TV_OS"], @app.platforms
    assert_equal 0, @ios.reads
    assert_empty UI.messages
  end

  def test_missing_app_fails_before_platform_lookup
    Spaceship::ConnectAPI::App.instance = nil
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_includes error.message, "Could not find com.windscribe"
    assert_empty @app.platforms
    assert_empty UI.messages
  end

  def test_missing_inputs_fail_before_authentication
    { "APP_VERSION" => " ", "RELEASE_NOTES" => "\n " }.each do |key, value|
      original = ENV[key]
      ENV[key] = value
      error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
      assert_equal "#{key} is required", error.message
      ENV[key] = original
    end
    assert_equal 0, @runner.auth_calls
    assert_empty Spaceship::ConnectAPI::App.lookups
  end

  def test_oversized_notes_fail_without_writes
    ENV["RELEASE_NOTES"] = "a" * 4_001
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_equal "Release notes exceed 4000 characters", error.message
    assert_equal 0, @tv.reads
    assert_empty UI.messages
  end

  def test_failed_readback_is_not_reported_as_success
    @tv.localizations.first.ignore_update = true
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_equal "Release-note verification failed for: fr-FR", error.message
    assert_equal 2, @tv.reads
    assert_empty UI.messages
  end

  def test_write_error_stops_without_success_and_rerun_completes_remaining_locale
    @tv.localizations.first.update_error = "Apple API error"
    error = assert_raises(RuntimeError) { @runner.run(:updateTVAppStoreReleaseNotes) }
    assert_equal "Apple API error", error.message
    assert_empty UI.messages
    @tv.localizations.first.update_error = nil
    @runner.run(:updateTVAppStoreReleaseNotes)
    assert @tv.localizations.all? { |localization| localization.updates.size == 1 }
    assert_equal ["Updated and verified release notes for: fr-FR"], UI.messages
  end

  def test_tv_ci_job_inherits_manual_input_gates_and_excludes_mrs
    ci = YAML.load_file(File.expand_path("../../.gitlab-ci.yml", __dir__))
    ios = ci.fetch("Update-App-Store-Release-Notes")
    tv = ci.fetch("Update-tvOS-App-Store-Release-Notes")
    assert_equal "Update-App-Store-Release-Notes", tv["extends"]
    assert_equal ["fastlane updateTVAppStoreReleaseNotes"], tv["script"]
    assert_equal ["fastlane updateAppStoreReleaseNotes"], ios["script"]
    assert_equal "deploy", ios["stage"]
    assert_equal [
      { "if" => "$CI_MERGE_REQUEST_ID", "when" => "never" },
      { "if" => "$APP_VERSION && $RELEASE_NOTES", "when" => "manual", "allow_failure" => false },
      { "when" => "never" }
    ], ios["rules"]
    refute tv.key?("rules")
    assert_includes ci.fetch("LintCheck").fetch("script"), "ruby fastlane/tests/app_store_release_notes_lanes_test.rb"
  end
end
