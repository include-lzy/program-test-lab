#!/usr/bin/env bash
# 用户态安装 CMake 与 Ninja（不需要 root），装到 ~/.local，不触碰系统目录。
set -euo pipefail

CMAKE_VER="4.5.0"
NINJA_VER="1.13.2"
PREFIX="$HOME/.local"
OPT="$PREFIX/opt"
mkdir -p "$PREFIX/bin" "$OPT" "$HOME/Downloads"

echo "=== [1/4] CMake $CMAKE_VER ==="
CMAKE_TGZ="cmake-${CMAKE_VER}-linux-x86_64.tar.gz"
CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/${CMAKE_TGZ}"
curl -fL --retry 3 -o "$HOME/Downloads/$CMAKE_TGZ" "$CMAKE_URL"
rm -rf "$OPT/cmake"
mkdir -p "$OPT/cmake"
tar -xzf "$HOME/Downloads/$CMAKE_TGZ" -C "$OPT/cmake" --strip-components=1
ln -sf "$OPT/cmake/bin/cmake" "$PREFIX/bin/cmake"
ln -sf "$OPT/cmake/bin/ctest" "$PREFIX/bin/ctest"
ln -sf "$OPT/cmake/bin/cpack" "$PREFIX/bin/cpack"
ln -sf "$OPT/cmake/bin/ccmake" "$PREFIX/bin/ccmake"

echo "=== [2/4] Ninja $NINJA_VER ==="
NINJA_URL="https://github.com/ninja-build/ninja/releases/download/v${NINJA_VER}/ninja-linux.zip"
curl -fL --retry 3 -o "$HOME/Downloads/ninja-linux.zip" "$NINJA_URL"
if command -v unzip >/dev/null 2>&1; then
  unzip -o "$HOME/Downloads/ninja-linux.zip" -d "$PREFIX/bin"
else
  python3 -c "import zipfile; zipfile.ZipFile('$HOME/Downloads/ninja-linux.zip').extractall('$PREFIX/bin')"
fi
chmod +x "$PREFIX/bin/ninja"

echo "=== [3/4] PATH 写入 ~/.bashrc（去重） ==="
LINE='export PATH="$HOME/.local/bin:$PATH"'
grep -Fqx "$LINE" "$HOME/.bashrc" 2>/dev/null || echo "$LINE" >> "$HOME/.bashrc"

echo "=== [4/4] 验证 ==="
export PATH="$PREFIX/bin:$PATH"
cmake --version
ninja --version
echo "USERENV_SETUP_OK"
