# Reyu Agent

The spec-driven coding agent CLI. Write the spec, let the agent build, and let the
checker prove it — [reyu.dev](https://reyu.dev).

This repository hosts the official binary releases and installer for `reyu-agent`.

## Install

With Homebrew:

    brew install srswti/tap/reyu-agent

Or with curl (installs to `~/.local/bin`):

    curl -fsSL https://raw.githubusercontent.com/SRSWTI/reyu-agent/main/install.sh | sh

Or grab a binary directly from [releases](https://github.com/SRSWTI/reyu-agent/releases):
`reyu-agent-<tag>-<target>.tar.gz` for

| Platform | Target |
|---|---|
| macOS, Apple Silicon | `aarch64-apple-darwin` |
| macOS, Intel | `x86_64-apple-darwin` |
| Linux, x86_64 | `x86_64-unknown-linux-musl` |
| Linux, arm64 | `aarch64-unknown-linux-musl` |

Every archive ships with a `.sha256` sidecar. Linux binaries are statically
linked (musl) and run on any modern distribution.

Verify the install:

    reyu-agent --version

## Notes

- The installer accepts an optional tag to pin a version:
  `install.sh v0.6.3`.
- Install location can be overridden with `REYU_INSTALL_DIR`.
- Checksum verification in the installer guards the download against
  corruption; Homebrew verifies the same checksums embedded in the
  [tap formula](https://github.com/SRSWTI/homebrew-tap).
