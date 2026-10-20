#!/usr/bin/env bash
# Installs the pinned Flutter SDK in Claude Code cloud sessions (idempotent).
# Used by the SessionStart hook in .claude/settings.json; can also be pasted
# as the environment's setup script: `bash tool/cloud_setup.sh`.
set -euo pipefail

FLUTTER_VERSION="3.47.7"
FLUTTER_SHA256="af7455f540df951184c7953fbe3cf884766e7541dacf8571f9f582db03dd6230"
FLUTTER_HOME="/opt/flutter"
ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"

# Local machines manage their own SDK.
if [[ "${CLAUDE_CODE_REMOTE:-}" != "true" && "${FORCE_CLOUD_SETUP:-}" != "1" ]]; then
  exit 0
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

installed_version() {
  [[ -f "${FLUTTER_HOME}/.cloud-setup-version" ]] && cat "${FLUTTER_HOME}/.cloud-setup-version" || true
}

if [[ "$(installed_version)" != "${FLUTTER_VERSION}" ]]; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  tmp="$(mktemp -d)"
  trap 'rm -rf "${tmp}"' EXIT
  curl -fsSL --retry 4 "${ARCHIVE_URL}" -o "${tmp}/flutter.tar.xz"
  echo "${FLUTTER_SHA256}  ${tmp}/flutter.tar.xz" | sha256sum -c --quiet -
  rm -rf "${FLUTTER_HOME}"
  tar -xJf "${tmp}/flutter.tar.xz" -C "$(dirname "${FLUTTER_HOME}")"
  # The archive is extracted as root; git refuses to operate on it otherwise.
  git config --global --add safe.directory "${FLUTTER_HOME}"
  echo "${FLUTTER_VERSION}" > "${FLUTTER_HOME}/.cloud-setup-version"
fi

ln -sf "${FLUTTER_HOME}/bin/flutter" /usr/local/bin/flutter
ln -sf "${FLUTTER_HOME}/bin/dart" /usr/local/bin/dart

# Cloud containers run as root; drop Flutter's "running as root" banner only.
without_root_banner() {
  "$@" 2>&1 | { grep -vE 'Woah! You appear|without superuser|^  /$|📎' || true; }
}

flutter config --no-analytics --no-cli-animations >/dev/null 2>&1
dart --disable-analytics >/dev/null 2>&1 || true

(cd "${repo_root}" && without_root_banner flutter pub get --suppress-analytics)
(cd "${repo_root}/example" && without_root_banner flutter pub get --suppress-analytics)

echo "Flutter ${FLUTTER_VERSION} ready."
