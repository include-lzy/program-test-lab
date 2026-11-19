# CI 多编译器矩阵骨架说明

## 目录结构

```
new-chat-2/
├── .github/workflows/ci.yml   # GitHub Actions 矩阵工作流
├── CMakeLists.txt            # CMake 工程定义
├── src/hello.cpp             # 示例程序（含内置自检）
└── README-CI.md              # 本说明
```

## 矩阵覆盖的组合

| 作业系统 | 编译器 | 生成器 | 说明 |
|---|---|---|---|
| ubuntu-latest | GCC 15（runner 默认） | Ninja | Linux 主链路 |
| ubuntu-latest | Clang | Ninja | 第二编译器，排查语法/UB |
| windows-latest | MSVC（Visual Studio 17 2022, x64） | VS 生成器 | Windows 编译器兼容 |

工作流触发条件：push 到 main/master、提 Pull Request，或在 Actions 页面手动 `workflow_dispatch`。

## 推送到 GitHub 后生效

本机当前未安装 git，需要先装 git 并在 GitHub 建仓库，然后：

```bash
git init
git add .
git commit -m "ci: add compiler matrix skeleton"
git branch -M main
git remote add origin <你的仓库地址>
git push -u origin main
```

推送后在仓库的 Actions 标签页查看三组作业是否全绿。

## 本地对应命令（WSL2 Ubuntu）

```bash
# 配置（需先装 cmake/ninja：sudo apt install cmake ninja-build）
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
# 编译
cmake --build build
# 测试
ctest --test-dir build --output-on-failure
```

不装 CMake 时的最小编译验证：

```bash
g++ -std=c++17 -Wall -Wextra src/hello.cpp -o hello && ./hello
```

## 如何扩展矩阵

在 `ci.yml` 的 `matrix.include` 里加条目即可，例如：

- 加 Clang 版本：复制 ubuntu + clang 条目，在依赖安装步指定 `clang-18`。
- 加 macOS：`os: macos-latest`，编译器用 `clang`/`clang++`。
- 加 ARM64：GitHub 目前无原生 ARM runner，需走云 ARM 实例或 QEMU，不能直接在本矩阵加。
- 加测试用例：在 `src/` 下新增源文件，`CMakeLists.txt` 里 `add_executable` + `add_test`。

## 已验证状态

- 示例源码已在 WSL2（GCC 15.2.0, `-Wall -Wextra`）编译并运行通过，输出 `a + b = 4`。
- CI 工作流文件尚未在 GitHub 实际跑过（本机无 git、未连远程仓库），推送后以 Actions 页面结果为准。
