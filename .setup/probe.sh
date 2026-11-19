#!/usr/bin/env bash
whoami
id
if sudo -n true 2>/dev/null; then
  echo "SUDO_NOPASSWD=yes"
else
  echo "SUDO_NOPASSWD=no"
fi
echo "--- tools ---"
for t in gcc g++ clang clang++ cmake ninja make; do
  p="$(command -v "$t" 2>/dev/null)"
  echo "$t: ${p:-MISSING}"
done
echo "--- os ---"
head -2 /etc/os-release
echo "--- apt cache ---"
command -v apt-get && echo apt-get-ok
