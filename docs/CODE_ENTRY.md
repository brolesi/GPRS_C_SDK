[![中文](https://img.shields.io/badge/中文-文档-blue)](CODE_ENTRY.zh.md)

# Code Entry

## Runtime entry chain

The application does not start at a conventional host `main()` function. The linker script [`platform/compilation/cust.ld`](../platform/compilation/cust.ld) declares `ENTRY(user_Main)`, and the platform firmware calls the registration bridge in [`init/src/sdk_init.c`](../init/src/sdk_init.c).

```text
platform firmware
  -> user_Init(T_INTERFACE_VTBL_TAG *pVtable)
     -> save the platform API table
     -> user_Main()
        -> PRONAME_MAIN()
           -> <project>_Main()
```

[`platform/compilation/cust_rules.mk`](../platform/compilation/cust_rules.mk) defines `PRONAME_MAIN=$(PROJ_NAME)_Main`. Therefore:

- `PROJ_NAME=app` resolves the user entry to [`app_Main()`](../app/src/app.c).
- `PROJ_NAME=gpio` resolves it to [`gpio_Main()`](../demo/gpio/src/demo_gpio.c).
- A new demo named `sensor` must expose `void sensor_Main(void)`.

## Adding an application

For the standard application template, edit `app/src/` and build:

```bash
bash scripts/build-sdk.sh app debug
```

For a demo, copy an existing directory under `demo/`, keep its module `Makefile`, and make the exported entry name match the directory/project name:

```c
void sensor_Main(void)
{
    /* Initialize the application and return control to the SDK scheduler. */
}
```

```bash
bash scripts/build-sdk.sh demo sensor debug
```

## First files to inspect

1. `init/target.def` selects the RDA8955 ASIC, flash model, and `csdk` platform.
2. `Makefile` assembles `init`, `libs`, and the selected project.
3. `<project>/Makefile` lists its sources and include dependencies.
4. `platform/compilation/cust_rules.mk` owns compile, archive, link, ELF-combine, and LOD-combine rules.
5. `platform/compilation/cust.ld` defines the user-code memory layout and linker entry.

Do not rename an entry function without also changing `PROJ_NAME`, because the generated `PRONAME_MAIN` reference will otherwise fail at link time.
