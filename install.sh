#!/usr/bin/env bash
# XCSP Launcher home-directory installer
# - Installs xcsp into ~/.local/opt/xcsp-launcher/<version> and symlinks ~/.local/bin/xcsp
# - Verifies checksums with cosign (if available) and sha256sum
# - Installs the XCSP3 solution checker jar under ~/.local/share/xcsp-launcher/tools/
# - Fetches solver config files (*.solver.yaml) into ~/.config/xcsp-launcher/solvers
# - Offers interactive installation of selected solvers using `xcsp install -c <file>`
#
# Usage:
#   ./install.sh [--version vX.Y.Z] [--prefix ~/.local] [--no-verify]
#                [--cosign-identity "<identity>"] [--yes]
#
# Defaults:
#   --prefix           $HOME/.local
#   --cosign-identity  "https://github.com/CPToolset/xcsp-launcher/.github/workflows/release.yml@refs/heads/main"
#   --version          latest GitHub release
#
# Notes:
#   * Requires: bash, curl, tar, sha256sum
#   * Optional: cosign (for signature verification), git or tar/unzip (to fetch solver configs)
#   * Supports Linux and macOS. Windows is not supported by this script.

set -euo pipefail

# ----------------------------
# Configurable defaults
# ----------------------------
REPO_SLUG="CPToolset/XCSP-Launcher"
IDENTITY_DEFAULT="https://github.com/CPToolset/xcsp-launcher/.github/workflows/release.yml@refs/heads/main"
PREFIX="${HOME}/.local"
RELEASE_TAG=""          # empty -> resolve latest
COSIGN_IDENTITY="${IDENTITY_DEFAULT}"
NO_VERIFY="false"
ASSUME_YES="false"

# ----------------------------
# Basic colored output helpers
# ----------------------------
bold()   { printf "\033[1m%s\033[0m\n" "$*"; }
info()   { printf "ℹ️  %s\n" "$*"; }
ok()     { printf "✅ %s\n" "$*"; }
warn()   { printf "⚠️  %s\n" "$*"; }
err()    { printf "❌ %s\n" "$*" >&2; }
die()    { err "$*"; exit 1; }

# Simple spinner for long-running steps (use: long_cmd & spin $! "Message")
spin() {
  local pid="$1"; shift
  local msg="$*"
  local frames='|/-\'
  local i=0
  printf "%s " "$msg"
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r%s %s" "$msg" "${frames:$i:1}"
    sleep 0.1
  done
  printf "\r%s … done\n" "$msg"
}

# ----------------------------
# Parse CLI args
# ----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)         RELEASE_TAG="$2"; shift 2 ;;
    --prefix)          PREFIX="$2"; shift 2 ;;
    --no-verify)       NO_VERIFY="true"; shift ;;
    --cosign-identity) COSIGN_IDENTITY="$2"; shift 2 ;;
    --yes|--assume-yes) ASSUME_YES="true"; shift ;;
    -h|--help)
      cat <<EOF
Usage: $0 [options]

Options:
  --version vX.Y.Z        Install specific tag (default: latest release)
  --prefix PATH           Install under this prefix (default: ${HOME}/.local)
  --no-verify             Skip cosign + sha256 verification
  --cosign-identity STR   Override cosign certificate-identity
  --yes                   Non-interactive: auto-accept defaults where possible
  -h, --help              Show this help

Examples:
  $0
  $0 --version v0.6.3
  $0 --prefix "\$HOME/.local"
EOF
      exit 0
      ;;
    *)
      die "Unknown option: $1 (use --help)"
      ;;
  esac
done

# ----------------------------
# Environment & directories
# ----------------------------
BIN_DIR="${PREFIX}/bin"
OPT_BASE="${PREFIX}/opt/xcsp-launcher"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-${HOME}/.cache}"
CONFIG_DIR="${XDG_CONFIG_HOME}/xcsp-launcher"
SOLVERS_DIR="${CONFIG_DIR}/solvers"
DATA_DIR="${XDG_DATA_HOME}/xcsp-launcher"
TOOLS_DIR="${DATA_DIR}/tools"
STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/xcsp-launcher"

mkdir -p "${BIN_DIR}" "${OPT_BASE}" "${SOLVERS_DIR}" "${TOOLS_DIR}" "${STATE_DIR}"

# ----------------------------
# Prerequisite checks
# ----------------------------
need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"; }
need_cmd curl
need_cmd tar
need_cmd sha256sum

HAS_COSIGN="false"
if command -v cosign >/dev/null 2>&1; then
  HAS_COSIGN="true"
fi

# ----------------------------
# OS / ARCH detection
# ----------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Linux|Darwin) : ;;
  *) die "Unsupported OS: $OS (only Linux/macOS supported)" ;;
esac

# ----------------------------
# Resolve release tag (latest if empty)
# ----------------------------
if [[ -z "${RELEASE_TAG}" ]]; then
  info "Resolving latest release tag…"
  # Parse from GitHub API without jq
  RELEASE_TAG="$(curl -fsSL "https://api.github.com/repos/${REPO_SLUG}/releases/latest" \
    | awk -F'"' '/"tag_name":/ {print $4}')"
  [[ -n "${RELEASE_TAG}" ]] || die "Could not determine latest release tag"
  ok "Latest release: ${RELEASE_TAG}"
else
  info "Using requested release: ${RELEASE_TAG}"
fi

# ----------------------------
# Build asset URLs for this OS
# ----------------------------
BASE_URL="https://github.com/${REPO_SLUG}/releases/download/${RELEASE_TAG}"
CHECKSUMS_TXT="${BASE_URL}/checksums.txt"
CHECKSUMS_SIG="${BASE_URL}/checksums.txt.sig"
CHECKSUMS_PEM="${BASE_URL}/checksums.txt.pem"

ASSET_NAME=""
IS_TARBALL="false"

if [[ "$OS" == "Linux" ]]; then
  # Prefer the standalone linux binary named 'xcsp'
  ASSET_NAME="xcsp"
elif [[ "$OS" == "Darwin" ]]; then
  # Prefer 'xcsp-macos', fallback to 'xcsp-<ver>-macos.tar.gz'
  CANDIDATE1="xcsp-macos"
  CANDIDATE2="xcsp-${RELEASE_TAG#v}-macos.tar.gz"
  # HEAD to see which exists
  if curl -fsI "${BASE_URL}/${CANDIDATE1}" >/dev/null 2>&1; then
    ASSET_NAME="${CANDIDATE1}"
  elif curl -fsI "${BASE_URL}/${CANDIDATE2}" >/dev/null 2>&1; then
    ASSET_NAME="${CANDIDATE2}"
    IS_TARBALL="true"
  else
    die "No macOS asset found for ${RELEASE_TAG}"
  fi
fi

ASSET_URL="${BASE_URL}/${ASSET_NAME}"

# ----------------------------
# Download dir
# ----------------------------
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# ----------------------------
# Download files with progress bars
# ----------------------------
download() {
  local url="$1" out="$2"
  curl -fL --progress-bar -o "$out" "$url"
}

bold "1) Downloading release artifacts (${RELEASE_TAG})"
info "Release: ${BASE_URL}"
download "${ASSET_URL}"        "${WORK_DIR}/${ASSET_NAME}"
download "${CHECKSUMS_TXT}"    "${WORK_DIR}/checksums.txt"
download "${CHECKSUMS_SIG}"    "${WORK_DIR}/checksums.txt.sig"
download "${CHECKSUMS_PEM}"    "${WORK_DIR}/checksums.txt.pem"
ok "Artifacts downloaded to ${WORK_DIR}"

# ----------------------------
# Verify checksums with cosign + sha256
# ----------------------------
if [[ "${NO_VERIFY}" == "false" ]]; then
  bold "2) Verifying checksums"
  if [[ "${HAS_COSIGN}" == "true" ]]; then
    info "cosign present: verifying the signed checksums.txt"
    set +e
    cosign verify-blob \
      --cert "${WORK_DIR}/checksums.txt.pem" \
      --signature "${WORK_DIR}/checksums.txt.sig" \
      --certificate-identity "${COSIGN_IDENTITY}" \
      --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
      "${WORK_DIR}/checksums.txt" >/dev/null 2>&1
    CS_RC=$?
    set -e
    if [[ $CS_RC -ne 0 ]]; then
      die "cosign verification failed. You can rerun with --no-verify to bypass."
    fi
    ok "cosign: Verified OK"
  else
    warn "cosign not found; skipping signature verification. (Install cosign or rerun with --no-verify to silence this warning.)"
  fi

  info "sha256sum: checking integrity of downloaded asset"
  # Only check the specific file; ignore missing others
  ( cd "${WORK_DIR}" && sha256sum --ignore-missing -c checksums.txt ) | grep -E "${ASSET_NAME}: OK" >/dev/null \
    || die "sha256 mismatch for ${ASSET_NAME}"
  ok "sha256sum: ${ASSET_NAME} matches checksums.txt"
else
  warn "Verification disabled by --no-verify"
fi

# ----------------------------
# Install under ~/.local/opt/xcsp-launcher/<version>
# ----------------------------
bold "3) Installing XCSP Launcher into home directory"
DEST_DIR="${OPT_BASE}/${RELEASE_TAG#v}"
mkdir -p "${DEST_DIR}"

if [[ "${IS_TARBALL}" == "true" ]]; then
  info "Extracting tarball to ${DEST_DIR}"
  tar -xzf "${WORK_DIR}/${ASSET_NAME}" -C "${DEST_DIR}" --strip-components=1
  # The tarball should contain a binary named 'xcsp'
  [[ -x "${DEST_DIR}/xcsp" ]] || die "Expected 'xcsp' binary not found in tarball"
else
  info "Placing binary in ${DEST_DIR}"
  install -m 0755 "${WORK_DIR}/${ASSET_NAME}" "${DEST_DIR}/xcsp"
fi

ln -sfn "${DEST_DIR}/xcsp" "${BIN_DIR}/xcsp"
ok "Installed: ${DEST_DIR}/xcsp"
ok "Symlinked: ${BIN_DIR}/xcsp -> ${DEST_DIR}/xcsp"

# ----------------------------
# Ensure PATH contains ~/.local/bin
# ----------------------------
if ! command -v xcsp >/dev/null 2>&1; then
  warn "xcsp not found in PATH."
  echo
  echo "Add this line to your shell profile (e.g., ~/.bashrc or ~/.zshrc):"
  echo "  export PATH=\"${BIN_DIR}:\$PATH\""
  echo
fi

# ----------------------------
# Install XCSP3 solution checker JAR
# ----------------------------
bold "4) Installing XCSP3 solution checker"
CHECKER_URL="https://raw.githubusercontent.com/CPToolset/XCSP-Launcher/main/xcsp/tools/xcsp3-solutionChecker-2.5.jar"
CHECKER_OUT="${TOOLS_DIR}/xcsp3-solutionChecker-2.5.jar"
download "${CHECKER_URL}" "${CHECKER_OUT}"
chmod 0644 "${CHECKER_OUT}"
ok "Checker installed at ${CHECKER_OUT}"

# ----------------------------
# Fetch solver config files (*.solver.yaml)
# - Try git for speed; otherwise download tarball archive
# ----------------------------
bold "5) Fetching solver configuration files into ${SOLVERS_DIR}"
TMP_SOLV="${WORK_DIR}/metrics-solvers"
mkdir -p "${TMP_SOLV}"

fetch_solvers_via_git() {
  command -v git >/dev/null 2>&1 || return 1
  git clone --depth 1 https://github.com/crillab/metrics-solvers.git "${TMP_SOLV}" >/dev/null 2>&1 || return 1
  return 0
}
fetch_solvers_via_tar() {
  local tar_url="https://github.com/crillab/metrics-solvers/archive/refs/heads/main.tar.gz"
  download "${tar_url}" "${WORK_DIR}/metrics-solvers.tar.gz"
  mkdir -p "${TMP_SOLV}"
  tar -xzf "${WORK_DIR}/metrics-solvers.tar.gz" -C "${WORK_DIR}"
  # Extracted folder name:
  local root="${WORK_DIR}/metrics-solvers-main"
  [[ -d "${root}" ]] || die "Unexpected archive layout for metrics-solvers"
  mv "${root}" "${TMP_SOLV}"
}

if fetch_solvers_via_git; then
  ok "Cloned metrics-solvers via git"
else
  warn "git not available or clone failed; falling back to tarball download"
  fetch_solvers_via_tar
  ok "Downloaded metrics-solvers archive"
fi

# Copy any *.solver.yaml files found anywhere in the repo into SOLVERS_DIR
FOUND_COUNT=0
while IFS= read -r -d '' f; do
  cp -f "$f" "${SOLVERS_DIR}/"
  FOUND_COUNT=$((FOUND_COUNT+1))
done < <(find "${TMP_SOLV}" -type f -name "*.solver.yaml" -print0)

if [[ "${FOUND_COUNT}" -gt 0 ]]; then
  ok "Copied ${FOUND_COUNT} solver config(s) to ${SOLVERS_DIR}"
else
  warn "No *.solver.yaml found in metrics-solvers repository."
fi

# ----------------------------
# Final checks & optional interactive solver install
# ----------------------------
bold "6) Post-install checks"
if command -v xcsp >/dev/null 2>&1; then
  ok "Command 'xcsp' is available: $(command -v xcsp)"
  xcsp --version || true
else
  warn "'xcsp' is not yet on PATH. You can run it via: ${DEST_DIR}/xcsp"
fi

# Offer interactive solver installation if configs exist
install_solvers_menu() {
  echo
  bold "Optional: Install solvers from configs in ${SOLVERS_DIR}"
  mapfile -t CFGS < <(find "${SOLVERS_DIR}" -maxdepth 1 -type f -name "*.solver.yaml" | sort)
  if [[ ${#CFGS[@]} -eq 0 ]]; then
    info "No solver config files (*.solver.yaml) found. Skipping."
    return 0
  fi

  echo "Available solver config files:"
  local i=1
  for f in "${CFGS[@]}"; do
    echo "  [$i] $(basename "$f")"
    i=$((i+1))
  done
  echo
  if [[ "${ASSUME_YES}" == "true" ]]; then
    info "--yes provided: skipping interactive selection."
    return 0
  fi
  read -rp "Enter numbers to install (space-separated, empty to skip): " -a picks
  if [[ ${#picks[@]} -eq 0 ]]; then
    info "No selection. Skipping solver installation."
    return 0
  fi
  for p in "${picks[@]}"; do
    if [[ "$p" =~ ^[0-9]+$ ]] && (( p>=1 && p<=${#CFGS[@]} )); then
      cfg="${CFGS[$((p-1))]}"
      echo
      info "Installing solver from $(basename "$cfg")"
      # Use xcsp CLI to install
      set +e
      xcsp install -c "$cfg"
      rc=$?
      set -e
      if [[ $rc -eq 0 ]]; then
        ok "Installed from $(basename "$cfg")"
      else
        warn "Install failed for $(basename "$cfg") (exit $rc)"
      fi
    else
      warn "Invalid selection: $p (ignored)"
    fi
  done
}

install_solvers_menu

echo
ok "XCSP Launcher ${RELEASE_TAG} installed successfully."
echo "Data dir:     ${DATA_DIR}"
echo "Config dir:   ${CONFIG_DIR}"
echo "Cache dir:    ${XDG_CACHE_HOME}/xcsp-launcher"
echo "Binary:       ${DEST_DIR}/xcsp (symlinked from ${BIN_DIR}/xcsp)"
