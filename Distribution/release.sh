#!/bin/bash
# Archive, export and upload the current scheme to App Store Connect via
# an App Store Connect API key — no interactive Apple ID sign-in needed.
#
# Requires: an API key (.p8) from App Store Connect > Users and Access >
# Integrations, its Key ID and Issuer ID. Defaults below match this repo's
# key; override with ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_PATH if it moves
# or rotates.
set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT="Pendulum.xcodeproj"
SCHEME="Pendulum"
ARCHIVE_PATH="app.xcarchive"
EXPORT_PATH="export"
EXPORT_OPTIONS="Distribution/ExportOptions.plist"

KEY_ID="${ASC_KEY_ID:-SVT2F44K38}"
ISSUER_ID="${ASC_ISSUER_ID:-095834f4-0427-46fe-8126-52b8ed4a825c}"
KEY_PATH="${ASC_KEY_PATH:-$HOME/.appstoreconnect/AuthKey_${KEY_ID}.p8}"

if [ ! -f "$KEY_PATH" ]; then
	echo "error: API key not found at $KEY_PATH" >&2
	exit 1
fi

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "==> Archiving $SCHEME (Release)"
xcodebuild archive \
	-project "$PROJECT" \
	-scheme "$SCHEME" \
	-configuration Release \
	-destination 'generic/platform=iOS' \
	-archivePath "$ARCHIVE_PATH" \
	-allowProvisioningUpdates \
	-authenticationKeyPath "$KEY_PATH" \
	-authenticationKeyID "$KEY_ID" \
	-authenticationKeyIssuerID "$ISSUER_ID"

echo "==> Exporting and uploading to App Store Connect"
xcodebuild -exportArchive \
	-archivePath "$ARCHIVE_PATH" \
	-exportPath "$EXPORT_PATH" \
	-exportOptionsPlist "$EXPORT_OPTIONS" \
	-allowProvisioningUpdates \
	-authenticationKeyPath "$KEY_PATH" \
	-authenticationKeyID "$KEY_ID" \
	-authenticationKeyIssuerID "$ISSUER_ID"

echo "==> Done"
