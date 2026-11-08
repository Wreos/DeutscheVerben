# iOS releases to TestFlight

Run **Actions → Upload iOS to TestFlight → Run workflow** on `main`.
The workflow checks formatting, runs the core tests, archives the iPhone app,
signs it and uploads it to App Store Connect. Apple processes the upload before
it appears in TestFlight. This does not submit an App Store review, publish the
app, or automatically invite testers. Builds are not uploaded on ordinary pushes.

## One-time Apple setup

1. Activate a personal Apple Developer Program membership. An invitation to
   an employer's team is separate from personal membership.
2. Register the explicit App ID `de.aleksandr.DeutscheVerben` in Certificates,
   Identifiers & Profiles, then create an iOS app record with that Bundle ID in
   App Store Connect. Keep this Bundle ID stable after the first upload.
3. Create an **Apple Distribution** certificate, with its private key, and export
   the pair from Keychain Access as a password-protected `.p12`.
4. Create an **App Store Connect** provisioning profile for that App ID and
   distribution certificate. Download the `.mobileprovision` file.
5. In App Store Connect → Users and Access → Integrations → App Store Connect API,
   request API access if prompted. Create a **team key** with the **Developer**
   role for build uploads. Record Key ID and Issuer ID and download the `.p8`
   private key. Apple only offers the private-key download once.

Do not use an employer's team or credentials for a personal app.
Creating keys and accepting Apple agreements are account-holder actions.

## GitHub settings

Under repository **Settings → Secrets and variables → Actions**, add:

| Type | Name | Value |
| --- | --- | --- |
| Variable | `APPLE_TEAM_ID` | Personal Developer Team ID (not the Issuer ID) |
| Secret | `ASC_KEY_ID` | API Key ID |
| Secret | `ASC_ISSUER_ID` | API Issuer ID |
| Secret | `ASC_PRIVATE_KEY` | Complete `.p8` contents, including header/footer and newlines |
| Secret | `IOS_DISTRIBUTION_P12_BASE64` | Base64 of the `.p12`, on one line |
| Secret | `IOS_DISTRIBUTION_P12_PASSWORD` | Password used to export the `.p12` |
| Secret | `IOS_PROVISION_PROFILE_BASE64` | Base64 of the `.mobileprovision`, on one line |

Use GitHub's secret fields or `gh secret set NAME < file` rather than putting
private values in shell command arguments, chat, or tracked files. For binary
files, pipe `base64 -i /path/to/file | tr -d '\n'` into `gh secret set NAME`.
These credentials are intentionally shared with GitHub Actions to sign and
upload builds. The job installs them in a temporary keychain and deletes its
temporary credential files even when the build fails. Build artifacts containing
credentials are not uploaded to GitHub. Renew certificates/profiles before expiry.

## Versions and validation

The marketing version comes from `MARKETING_VERSION` in the Xcode project
(currently `1.0`). If regenerating the project, also update the version in
`scripts/generate-project.rb`. Each workflow attempt uses the workflow run number and
attempt number (`1.1`, `1.2`, `2.1`, …) as its build number; Xcode is told not to replace it. Avoid
concurrent local uploads using the same build number. Release jobs run serially.

The first successful signed upload still requires real Apple credentials and an
active membership. Local unsigned builds only verify compilation, not signing,
profile validity, Apple processing, or App Store acceptance. Check TestFlight
after the first successful run and complete any export-compliance questions.

## References

- [Apple: upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
- [Apple: creating App Store Connect API keys](https://developer.apple.com/documentation/appstoreconnectapi/creating-api-keys-for-app-store-connect-api)
