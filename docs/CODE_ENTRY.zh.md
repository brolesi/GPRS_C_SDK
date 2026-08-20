[![English](https://img.shields.io/badge/English-Docs-green)](CODE_ENTRY.md)

# 代码入口

## 运行入口链路

应用不是从普通主机程序的 `main()` 开始。[`platform/compilation/cust.ld`](../platform/compilation/cust.ld) 用 `ENTRY(user_Main)` 声明链接入口，平台固件通过 [`init/src/sdk_init.c`](../init/src/sdk_init.c) 中的注册桥接进入用户代码。

```text
平台固件
  -> user_Init(T_INTERFACE_VTBL_TAG *pVtable)
     -> 保存平台 API 表
     -> user_Main()
        -> PRONAME_MAIN()
           -> <项目名>_Main()
```

[`platform/compilation/cust_rules.mk`](../platform/compilation/cust_rules.mk) 定义 `PRONAME_MAIN=$(PROJ_NAME)_Main`，因此：

- `PROJ_NAME=app` 对应 [`app_Main()`](../app/src/app.c)。
- `PROJ_NAME=gpio` 对应 [`gpio_Main()`](../demo/gpio/src/demo_gpio.c)。
- 新增名为 `sensor` 的示例时，必须提供 `void sensor_Main(void)`。

## 新增应用

使用标准应用模板时，修改 `app/src/` 后构建：

```bash
bash scripts/build-sdk.sh app debug
```

新增示例时，可以复制 `demo/` 下已有目录，保留模块 `Makefile`，并让导出的入口名与目录/项目名一致：

```c
void sensor_Main(void)
{
    /* 初始化应用，然后将控制权交回 SDK 调度器。 */
}
```

```bash
bash scripts/build-sdk.sh demo sensor debug
```

## 建议优先阅读的文件

1. `init/target.def` 选择 RDA8955 芯片、Flash 型号和 `csdk` 平台。
2. `Makefile` 组合 `init`、`libs` 与所选项目。
3. `<项目>/Makefile` 列出项目源码和头文件依赖。
4. `platform/compilation/cust_rules.mk` 定义编译、归档、链接、ELF 合并和 LOD 合并规则。
5. `platform/compilation/cust.ld` 定义用户代码内存布局和链接入口。

不要只修改入口函数名而不修改 `PROJ_NAME`，否则生成的 `PRONAME_MAIN` 引用会在链接阶段失败。
