# Security Policy

## Supported versions

Mawaqit is under active development and ships from the `main` branch. Security
fixes are applied to the latest release; please reproduce against the newest
version before reporting.

| Version | Supported |
| --- | --- |
| Latest release | ✅ |
| Older releases | ❌ |

## Reporting a vulnerability

Please **do not** open a public issue for a security problem.

<!-- TODO: add a private security contact (email or GitHub private vulnerability
     reporting). Until then, use GitHub's "Report a vulnerability" button under
     the repository's Security tab if it is enabled. -->

Please include:

- A description of the issue and its impact.
- Steps to reproduce (a proof of concept if possible).
- The affected version/commit and your environment (device, Android version).

You can expect an acknowledgement of your report, and we will keep you updated
on the fix and disclosure timeline. Please give us a reasonable window to release
a fix before disclosing publicly.

## Scope

This app stores no accounts or server-side data; prayer times are computed
on-device. Areas of particular interest are the OTA update path (manifest
download, SHA-256 verification, package install) and the Android alarm/
notification pipeline.
