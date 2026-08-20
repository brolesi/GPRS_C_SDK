[![English](https://img.shields.io/badge/English-Docs-green)](ARCHITECTURE.md)

# 架构说明

## 源码分层

```text
应用层：    app/ 或 demo/<名称>/        项目专用的 <名称>_Main()
公共库：    libs/                       GPS、JSON、界面和工具库
SDK 桥接：  init/                       API 表注册与用户入口分发
公共 API：  include/                    提供给应用的头文件
平台层：    platform/                   芯片定义、二进制库和构建工具
```

根 `Makefile` 的 `LOCAL_MODULE_DEPENDS` 将 `init`、`libs` 和 `PROJECT_PATH` 加入顶层镜像。每个模块都有自己的 `Makefile`；递归 Make 编译源码，并归档为 `lib<模块>_<配置>.a`。

## 构建与镜像生成链路

```text
C/C++/汇编源码
  -> mips-elf-gcc / as
  -> 各模块静态库
  -> mips-elf-ld + cust.ld + ROM 符号
  -> 应用 ELF 和 map
  -> elfCombine.pl + platform/csdk/<配置>/*.elf
  -> 合并 ELF
  -> objcopy S-record -> 应用 LOD
  -> lodtool.py + platform/csdk/<配置>/*.lod
  -> 平台/应用合并烧录 LOD
```

`init/target.def` 当前选择 `8955` 芯片、`flsh_spi32m` Flash 型号和 `csdk` 应用平台。`platform/csdk/memd.def` 提供用户 RAM/ROM 限制。debug 和 release 平台目录都必须各自包含且仅包含一个 ELF 和一个 LOD。

## 主要产物

以 `demo gpio` 为例：

- `build/gpio/gpio.elf`：与平台 ELF 合并前的用户应用。
- `build/gpio/gpio.map`：用于入口和容量检查的符号/内存映射。
- `hex/gpio/gpio_BASE_csdk_<配置>.elf`：可检查的合并 ELF。
- `hex/gpio/gpio_flash_<配置>.lod`：应用 LOD。
- `hex/gpio/gpio_B2130_<配置>.lod`：平台与应用合并后的烧录镜像。

## 安全边界

维护入口 [`scripts/build-sdk.sh`](../scripts/build-sdk.sh) 只通过 Make 变量选择项目，特意避开旧 `build.sh` 中的 `sed` 操作，因此切换示例不会污染源码。脚本还会先校验平台输入以及生成文件数量，再报告成功。

编译成功只能证明源码、工具链和链接链路能够配合工作，不能证明入网、SIM、射频性能、GNSS 接收、外设接线、电源稳定性、下载或启动行为；这些项目必须在目标硬件上测试。
