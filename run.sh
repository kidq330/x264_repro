#!/usr/bin/env bash
# Reproduces the macOS archive naming bug (macos-archive-naming.md §5): in a Mix release, the H.264 encoder's
# av_log_set_level(AV_LOG_QUIET) lands in one libavutil image while libavcodec/libx264 log through another, so
# `[libx264 @ …]` lines appear on stderr. From the build tree they don't.
#
# Usage: run.sh [WORK_DIR]
# The project is copied into WORK_DIR on every run, so edits here take effect; deps and _build are kept.
set -euo pipefail

src=$(cd "$(dirname "$0")" && pwd)
work=${1:-$(mktemp -d -t x264_repro)}
mkdir -p "$work"
cp "$src/mix.exs" "$src/.formatter.exs" "$work/"
rm -rf "$work/lib" && cp -R "$src/lib" "$work/lib"
cd "$work"
echo "work dir: $work"

mix local.hex --force --if-missing >/dev/null
mix local.rebar --force --if-missing >/dev/null
mix deps.get >/dev/null

# $1 = label. Prints the libx264 line count and the REPRO lines; full output stays in $1.out / $1.err.
report() {
  local x264
  x264=$(grep -c '\[libx264 @' "$1.err" || true)
  echo "== $1: [libx264 @ ...] lines on stderr: $x264"
  grep '^REPRO' "$1.out" | sed 's/^REPRO /   /'
}

mix compile &>/dev/null
echo "mix compile (dev) finished"
mix run -e 'Repro.run()' >tree.out 2>tree.err
echo "run (dev) finished"
report tree

MIX_ENV=prod mix release --overwrite --quiet &>/dev/null
echo "mix compile (release) finished"
_build/prod/rel/repro/bin/repro eval 'Repro.run()' >release.out 2>release.err
echo "run (release) finished"
report release
