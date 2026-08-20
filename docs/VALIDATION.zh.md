[![English](https://img.shields.io/badge/English-Docs-green)](VALIDATION.md)

# 验证记录

## 范围与环境

- 日期：2026-08-20。
- 主机：Windows + WSL2 Ubuntu 22.04。
- 工具链：项目文档指定的 GPRS_CSDTK MIPS GCC 4.4.2，并通过 `prepare-runtime-links.sh` 准备兼容运行环境。
- 目标：仓库内 `demo/gpio`，分别独立构建 debug 和 release。
- 方法：使用 [`scripts/validate-sdk.sh`](../scripts/validate-sdk.sh)，每种配置都复制到全新的纯 ASCII `/tmp` 目录构建。

## 实测结果

| 检查项 | Debug | Release |
| --- | ---: | ---: |
| 构建退出状态 | 通过 | 通过 |
| 编译警告 / 错误 | 0 / 0 | 0 / 0 |
| 构建报告 ROM 使用 | 688 / 1,048,576 字节 | 688 / 1,048,576 字节 |
| 构建报告 RAM 使用 | 48 / 1,048,576 字节 | 48 / 1,048,576 字节 |
| 合并 ELF 大小 | 12,499,972 字节 | 12,108,072 字节 |
| 合并 ELF 入口 | `0x88010010` | `0x88010010` |
| 合并 LOD 大小 | 5,456,784 字节 | 5,456,784 字节 |
| 合并 LOD SHA-256 | `1d63b9d781744f8c560107c04868691a4b65163145058b6ed4fa01b8c50e076e` | `9c9dac14ad82c4f3800c15a26d989109db1e4c196ea6c85c82d71806ae3382d8` |

两个合并镜像均可识别为 ELF32、小端、MIPS R3000。应用 ELF 与 map 均包含 `gpio_Main`，map 包含 `user_Init`，生成的 LOD 包含地址记录。两种构建前后，根 `Makefile` 的 SHA-256 始终为 `8fdc7a5e481bef0056684988b6796d79c234021e23d5f332f65e033e73b43629`。

合并 ELF 会包含临时构建目录的调试路径，因此每次使用新临时目录时，其字节哈希可能变化。以上 LOD 哈希在重复运行中保持一致，更适合作为该旧版构建链的可重复性指标。

## 复现命令

```bash
CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK bash scripts/validate-sdk.sh
```

如果缺少命令、平台输入文件数量异常、Make 改变源码 `Makefile`、日志出现警告/错误、产物缺失、ELF 元数据不正确、入口符号不存在或 LOD 没有地址记录，脚本会立即失败。

## 未验证项目

本次没有连接设备，因此未验证烧录、启动、UART 日志、SIM 识别、GSM/GPRS 入网、通话/短信、GNSS、射频、外设、FOTA 和持续供电。发布前必须使用目标模组版本、计划使用的电源、SIM/运营商、天线和当地网络进行真机测试。
