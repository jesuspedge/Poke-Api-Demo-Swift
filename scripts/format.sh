#!/bin/sh
# Formats the Swift sources in place with swift-format using .swift-format.
set -eu
cd "$(dirname "$0")/.."
xcrun swift-format format --in-place --recursive --parallel \
    "Poke Api Demo" "Poke Api DemoTests" "Poke Api DemoUITests"
