# App Store release notes

These manual jobs update **What's New in This Version** for an existing editable App Store version. They do not update TestFlight beta test notes.

Run a pipeline on a branch containing the release-notes jobs with:

- `APP_VERSION`: the editable version in App Store Connect for the chosen platform, for example `1.0.5` for tvOS.
- `RELEASE_NOTES`: the text to publish. Literal `\n` sequences are converted to line breaks. Empty notes and notes over 4,000 characters are rejected.

Then play the job for the intended platform:

- **iOS:** `Update-App-Store-Release-Notes` (`fastlane updateAppStoreReleaseNotes`).
- **Apple TV / tvOS:** `Update-tvOS-App-Store-Release-Notes` (`fastlane updateTVAppStoreReleaseNotes`).

Both use the existing App Store Connect API-key variables (`UPLOAD_KEY_ID`, `UPLOAD_ISSUER_ID`, `UPLOAD_KEY`). No signing profiles or binary upload are required to update release notes.

Each job explicitly selects its platform within `com.windscribe` and checks that the editable version exactly matches `APP_VERSION` before writing. The version must already exist and be editable in App Store Connect; the job does not create it or fall back to another platform. Even if iOS and tvOS have identical version numbers, each job only updates its own platform.

The job fetches all existing localization resources, updates only `whatsNew`, skips values that already match, and reads every value back after the update. An API error or mismatched read-back fails the job. Updates across locales are not atomic: if a run fails partway through, rerun with the same inputs to finish the remaining locales.

Translation is not performed; the supplied `RELEASE_NOTES` value is copied to every locale, replacing any existing localized notes. Missing locale resources are not created.

The jobs are manual, require both inputs, and are excluded from MR pipelines. They do not create metadata files, upload a binary or screenshots, distribute to testers, or submit or release the version. Run them only when the supplied text is approved for the selected version.
