[![English](https://img.shields.io/badge/English-README-green)](README.md)

# 安信可 GPRS C SDK

用于安信可 A9/A9G 模组及兼容 RDA8955 硬件的 C 语言应用开发 SDK。仓库的 [`demo/`](demo/) 提供外设、网络、通话、GNSS、存储、音频和云平台等示例。

> **生命周期说明：** 这是面向 2G/GPRS 的历史 SDK，仓库最近更新时间和已发布版本均较早。新产品立项前，请确认当地 2G 网络、硬件版本及 Release 说明。现有 Tag 沿用项目原有的 `V2.xxx` 命名方式，不是语义化版本格式。

## 支持的硬件

- A9：四频 GSM/GPRS 模组。
- A9G：在 A9 功能基础上集成 GPS/BDS。
- A9/A9G 开发板（Pudding 开发板）。
- 其他 RDA8955 方案理论上可能兼容，但必须在目标硬件上验证。

模组峰值电流接近 2 A，应为 `VBAT` 提供稳定的 3.4–4.2 V 电源，或使用开发板的 5 V 稳压输入。开发板 USB 接口是 USB 1.1 设备接口，不是 USB 转串口；下载和串口调试需要将 USB 转串口模块连接到 `HST_TX`、`HST_RX`。

## 仓库结构

| 路径 | 用途 |
| --- | --- |
| `app/` | 应用模板，应用入口为 `app_Main()` |
| `demo/` | GPIO、UART、MQTT、GPS、短信、文件系统等可运行示例 |
| `init/` | SDK 到用户应用的启动桥接层 |
| `libs/` | 公共源码库 |
| `include/` | SDK 公共头文件 |
| `platform/` | 构建规则、链接脚本、平台 ELF/LOD 和库文件 |
| `scripts/` | 不改源码的构建入口和可重复验证脚本 |

代码执行和构建链路请参阅[代码入口](docs/CODE_ENTRY.zh.md)与[架构说明](docs/ARCHITECTURE.zh.md)。

## 环境要求

- Linux 或 WSL2；本仓库已在 WSL2 Ubuntu 22.04 验证。
- GNU Make、Bash、Perl 及常用 Unix 工具。
- [GPRS_CSDTK](https://github.com/Ai-Thinker-Open/GPRS_CSDTK) 中匹配的旧版 MIPS 工具链。
- 仓库内 `platform/csdk/debug` 和 `platform/csdk/release` 平台文件；发布包可从 [GitHub Releases](https://github.com/Ai-Thinker-Open/GPRS_C_SDK/releases) 获取。

旧版编译器对中文路径和 Windows 挂载路径较敏感。建议将两个仓库都放在 Linux 文件系统的纯英文路径下。验证脚本会自动复制到独立的 ASCII `/tmp` 路径构建。

## 构建方法

先准备 GPRS_CSDTK 兼容运行环境并加入工具链：

```bash
export CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK
export TOOLCHAIN_ROOT="$(bash "$CSDTK_ROOT/prepare-runtime-links.sh" --tool-root)"
export RUNTIME_LIB_ROOT="$(bash "$CSDTK_ROOT/prepare-runtime-links.sh" --runtime-lib)"
export PATH="$TOOLCHAIN_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$RUNTIME_LIB_ROOT:$TOOLCHAIN_ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

构建 GPIO 示例或应用模板：

```bash
bash scripts/build-sdk.sh demo gpio debug
bash scripts/build-sdk.sh demo gpio release
bash scripts/build-sdk.sh app debug
```

新脚本通过 Make 命令行选择 `PROJECT_PATH`，不会修改根 `Makefile`。产物位于 `build/<项目>/` 和 `hex/<项目>/`。旧 `build.sh` 为兼容性而保留，但它会改写 `Makefile` 第 15 行，日常使用建议采用新入口。

## 可重复验证

在相互隔离的目录中分别全量构建 GPIO 的 debug 和 release：

```bash
CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK bash scripts/validate-sdk.sh
```

脚本会拒绝编译警告和错误、确认 `Makefile` 未改变、检查生成的 ELF32 小端 MIPS 文件、确认 `gpio_Main` 与 `user_Init`，并检查合并后的 LOD 地址记录。实测数据和未覆盖的硬件测试边界见[验证记录](docs/VALIDATION.zh.md)。

## 文档与反馈

- [SDK 文档仓库](https://github.com/Ai-Thinker-Open/GPRS_C_SDK_DOC)
- [在线中文文档](https://ai-thinker-open.github.io/GPRS_C_SDK_DOC/zh/)
- [示例目录](demo/)
- [问题反馈](https://github.com/Ai-Thinker-Open/GPRS_C_SDK/issues)

本仓库采用 [MIT License](LICENSE)。欢迎通过 Pull Request 提交问题修复和文档改进。
