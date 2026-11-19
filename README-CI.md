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
| windows-latest | MSVC（Visual Studio 18 2026, x64，runner 预装） | VS 生成器 | Windows 编译器兼容 |

工作流触发条件：push 到 main/master、提 Pull Request，或在 Actions 页面手动 `workflow_dispatch`。

## 远端仓库与当前运行状态

- 远端仓库：`https://github.com/include-lzy/program-test-lab`（SSH remote `git@github.com:include-lzy/program-test-lab.git`）。
- 本地 Git 2.56.0.4，分支 `main`，跟踪 `origin/main`。
- 首次推送命令（已执行过，供参考）：

```bash
git init
git add .
git commit -m "ci: add compiler matrix skeleton"
git branch -M main
git remote add origin git@github.com:include-lzy/program-test-lab.git
git push -u origin main
```

推送后在仓库的 Actions 标签页查看三组作业是否全绿。

### 最近一次 CI 实测结论（2026-11-19，run `3a0f2b2`，run id `44510987348`，三组全绿）

| 作业系统 | 编译器 | 结论 |
|---|---|---|
| ubuntu-latest | GCC | 通过（Configure / Build / Test 成功） |
| ubuntu-latest | Clang | 通过（Configure / Build / Test 成功） |
| windows-latest | MSVC | 通过（Configure / Build / Test 成功） |

**Windows 组根因与修复（已验证）**：runner 镜像预装的是 Visual Studio 18 Enterprise（路径 `C:\Program Files\Microsoft Visual Studio\18\Enterprise`），而工作流最初写死生成器 `Visual Studio 17 2022`，CMake 探测不到 VS17 实例，Configure 报 `could not find any instance of Visual Studio`。改为 `Visual Studio 18 2026`（CMake 4.2+ 新增，runner cmake 4.4.5 支持）后全绿。若将来 runner 镜像换成 VS2022，需把生成器名改回 `Visual Studio 17 2022`。

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

- 示例源码已在 WSL2 编译并运行通过：GCC 15.2.0 与 Clang 21.1.8（`-Wall -Wextra`）均输出 `a + b = 4`。
- CI 工作流已在远端实际跑通：GCC、Clang、MSVC 三组 Configure/Build/Test 全部 success（run `aeef0a7`）。
