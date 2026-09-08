# App Store release notes

Run a pipeline for the release branch with:

- `APP_VERSION`: the editable iOS version in App Store Connect, for example `3.11.0`.
- `RELEASE_NOTES`: the text to publish. Literal `\n` sequences are converted to line breaks.

Then play `Update-App-Store-Release-Notes`.

The job fetches all localization resources, updates only `whatsNew`, skips values that already match, and reads every value back after the update. It does not create metadata files or upload a binary or screenshots, and it does not submit or release the version.

Translation is not performed; the supplied `RELEASE_NOTES` value is copied to every locale.
