require "minitest/autorun"

require_relative "../app_store_release_notes"

class AppStoreReleaseNotesTest < Minitest::Test
  class Localization
    attr_reader :locale, :updates
    attr_accessor :whats_new

    def initialize(locale:, whats_new: nil)
      @locale = locale
      @whats_new = whats_new
      @updates = []
    end

    def update(attributes:)
      @updates << attributes
      @whats_new = attributes.fetch("whats_new")
    end
  end

  class Version
    def initialize(localizations)
      @localizations = localizations
    end

    def get_app_store_version_localizations
      @localizations
    end
  end

  def test_updates_every_localization_with_only_whats_new
    english = Localization.new(locale: "en-US")
    french = Localization.new(locale: "fr-FR")

    changed = AppStoreReleaseNotes.update(
      version: Version.new([french, english]),
      description: "First line\\nSecond line"
    )

    assert_equal ["en-US", "fr-FR"], changed
    assert_equal [{ "whats_new" => "First line\nSecond line" }], english.updates
    assert_equal [{ "whats_new" => "First line\nSecond line" }], french.updates
  end

  def test_skips_localizations_that_already_match
    english = Localization.new(locale: "en-US", whats_new: "No changes")

    changed = AppStoreReleaseNotes.update(
      version: Version.new([english]),
      description: "No changes"
    )

    assert_empty changed
    assert_empty english.updates
  end

  def test_rejects_empty_release_notes
    error = assert_raises(ArgumentError) do
      AppStoreReleaseNotes.update(
        version: Version.new([Localization.new(locale: "en-US")]),
        description: " \n"
      )
    end

    assert_equal "Release notes are empty", error.message
  end

  def test_rejects_release_notes_over_apple_limit
    error = assert_raises(ArgumentError) do
      AppStoreReleaseNotes.update(
        version: Version.new([Localization.new(locale: "en-US")]),
        description: "a" * 4_001
      )
    end

    assert_equal "Release notes exceed 4000 characters", error.message
  end

  def test_rejects_versions_without_localizations
    error = assert_raises(ArgumentError) do
      AppStoreReleaseNotes.update(
        version: Version.new([]),
        description: "Release notes"
      )
    end

    assert_equal "The editable iOS version has no localizations", error.message
  end
end
