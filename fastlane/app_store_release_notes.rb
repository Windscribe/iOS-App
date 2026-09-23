module AppStoreReleaseNotes
  MAX_LENGTH = 4_000

  def self.update(version:, description:)
    value = normalize(description)
    localizations = version.get_app_store_version_localizations
    raise ArgumentError, "The editable App Store version has no localizations" if localizations.empty?

    changed_locales = []
    localizations.sort_by(&:locale).each do |localization|
      next if localization.whats_new.to_s.strip == value

      localization.update(attributes: { "whats_new" => value })
      changed_locales << localization.locale
    end

    stored_values = version.get_app_store_version_localizations.to_h do |localization|
      [localization.locale, localization.whats_new.to_s.strip]
    end
    mismatched_locales = localizations.each_with_object([]) do |localization, result|
      result << localization.locale unless stored_values[localization.locale] == value
    end
    unless mismatched_locales.empty?
      raise ArgumentError, "Release-note verification failed for: #{mismatched_locales.join(', ')}"
    end

    changed_locales
  end

  def self.normalize(description)
    value = description.to_s.gsub("\\n", "\n").strip
    raise ArgumentError, "Release notes are empty" if value.empty?
    if value.length > MAX_LENGTH
      raise ArgumentError, "Release notes exceed #{MAX_LENGTH} characters"
    end

    value
  end
  private_class_method :normalize
end
