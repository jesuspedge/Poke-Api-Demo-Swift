#!/bin/sh
# Lints the Swift sources with swift-format (bundled with Xcode 16+) using .swift-format.
# Fails on any finding, so it can gate CI.
set -eu
cd "$(dirname "$0")/.."
xcrun swift-format lint --strict --recursive --parallel \
    "Poke Api Demo" "Poke Api DemoTests" "Poke Api DemoUITests"
