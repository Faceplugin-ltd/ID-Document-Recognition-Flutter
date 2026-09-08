#!/bin/bash
# Re-sign nested dcrcore.framework inside embedded docsdk.framework.
# Run after "[CP] Embed Pods Frameworks" so the app identity seals the nested engine.
set -euo pipefail

DOCSDK_FW="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/docsdk.framework"
NESTED="${DOCSDK_FW}/Frameworks/dcrcore.framework"

if [ ! -d "${NESTED}" ]; then
  exit 0
fi

if [ -z "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] || [ "${EXPANDED_CODE_SIGN_IDENTITY}" = "-" ]; then
  echo "warning: EXPANDED_CODE_SIGN_IDENTITY unset; skipping nested dcrcore codesign" >&2
  exit 0
fi

echo "Signing nested dcrcore.framework (${TARGET_NAME})"
/usr/bin/codesign --remove-signature "${NESTED}" 2>/dev/null || true
/usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
  --preserve-metadata=identifier,entitlements,flags \
  --timestamp=none \
  "${NESTED}"

echo "Re-signing docsdk.framework"
/usr/bin/codesign --remove-signature "${DOCSDK_FW}" 2>/dev/null || true
/usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
  --preserve-metadata=identifier,entitlements,flags \
  --timestamp=none \
  "${DOCSDK_FW}"
