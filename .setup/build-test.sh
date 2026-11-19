#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
SRC=/mnt/c/Users/BILL/Doubao/chats/2026-11-18/new-chat-2
rm -rf "$HOME/build-test"
echo "=== cmake configure ==="
cmake -S "$SRC" -B "$HOME/build-test" -G Ninja -DCMAKE_BUILD_TYPE=Release
echo "=== build ==="
cmake --build "$HOME/build-test"
echo "=== ctest ==="
ctest --test-dir "$HOME/build-test" --output-on-failure
echo "=== run binary ==="
"$HOME/build-test/hello"
echo "BUILD_TEST_OK"
