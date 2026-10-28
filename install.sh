#!/bin/sh
# Reyu Agent installer — curl | sh
#
#   curl -fsSL https://raw.githubusercontent.com/SRSWTI/reyu-agent/main/install.sh | sh
#
# Detects your platform, downloads the matching release archive from
# github.com/SRSWTI/reyu-agent, verifies its SHA-256 against the published
# .sha256 sidecar, installs the `reyu-agent` binary to ~/.local/bin (or
# $REYU_INSTALL_DIR), and prints the installed version.
#
# Options:
#   install.sh [tag]    install a specific release tag instead of latest
#   REYU_INSTALL_DIR    override the install directory (default ~/.local/bin)
set -eu

REPO="${REYU_DIST_REPO:-SRSWTI/reyu-agent}"
BINARY="reyu-agent"

need_cmd() {
    command -v "$1" > /dev/null 2>&1 || err "need '$1' (not found)"
}

err() {
    echo "error: $1" >&2
    exit 1
}

# Works for both pretty-printed and single-line GitHub API JSON.
latest_tag() {
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "User-Agent: reyu-agent-install" \
        "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n 1
}

file_sha256() {
    if command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

main() {
    need_cmd curl
    need_cmd tar

    case "$(uname -s)" in
        Darwin) os=apple-darwin ;;
        Linux)  os=unknown-linux-musl ;;
        *) err "unsupported OS: $(uname -s) (macOS and Linux are supported)" ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)  arch=x86_64 ;;
        aarch64|arm64) arch=aarch64 ;;
        *) err "unsupported architecture: $(uname -m)" ;;
    esac
    target="${arch}-${os}"

    tag="${1:-$(latest_tag)}"
    [ -n "${tag}" ] || err "failed to determine latest release tag"

    base="https://github.com/${REPO}/releases/download/${tag}"
    archive="${BINARY}-${tag}-${target}.tar.gz"

    install_dir="${REYU_INSTALL_DIR:-${HOME}/.local/bin}"
    tmp="$(mktemp -d)"
    trap 'rm -rf "${tmp}"' EXIT

    echo "downloading ${BINARY} ${tag} for ${target}..."
    curl -fsSL -o "${tmp}/${archive}" "${base}/${archive}" \
        || err "download failed: ${base}/${archive}
does a ${target} build exist for ${tag}? see https://github.com/${REPO}/releases"

    # Verify the download against the published checksum.
    curl -fsSL -o "${tmp}/${archive}.sha256" "${base}/${archive}.sha256" \
        || err "download failed: ${base}/${archive}.sha256"
    expected="$(cut -d' ' -f1 "${tmp}/${archive}.sha256")"
    [ -n "${expected}" ] || err "could not read checksum for ${archive}"
    actual="$(file_sha256 "${tmp}/${archive}")"
    [ "${actual}" = "${expected}" ] || err "checksum mismatch for ${archive}
  expected ${expected}
  got      ${actual}"

    tar xzf "${tmp}/${archive}" -C "${tmp}"
    [ -f "${tmp}/${BINARY}" ] || err "archive did not contain ${BINARY}"

    mkdir -p "${install_dir}"
    dest="${install_dir}/${BINARY}"
    mv -f "${tmp}/${BINARY}" "${dest}"
    chmod +x "${dest}"

    echo "${BINARY} ${tag} installed to ${dest}"

    case ":${PATH}:" in
        *":${install_dir}:"*) ;;
        *)
            echo "note: ${install_dir} is not in PATH; add it to your shell config, e.g.:"
            echo "  export PATH=\"${install_dir}:\$PATH\""
            ;;
    esac

    echo
    "${dest}" --version
}

main "$@"
