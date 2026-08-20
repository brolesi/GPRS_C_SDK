[![中文](https://img.shields.io/badge/中文-文档-blue)](ARCHITECTURE.zh.md)

# Architecture

## Source layers

```text
Application:  app/ or demo/<name>/       project-specific <name>_Main()
Libraries:    libs/                      reusable GPS, JSON, UI, and utility code
SDK bridge:   init/                      API-table registration and user entry dispatch
Public API:   include/                   headers exposed to applications
Platform:     platform/                  chip definitions, binary libraries, build tools
```

`LOCAL_MODULE_DEPENDS` in the root `Makefile` brings `init`, `libs`, and `PROJECT_PATH` into the top-level image. Each module has a local `Makefile`; recursive Make compiles sources and archives them as `lib<module>_<profile>.a`.

## Build and image flow

```text
C/C++/assembly sources
  -> mips-elf-gcc / as
  -> per-module static archives
  -> mips-elf-ld + cust.ld + ROM symbols
  -> application ELF and map
  -> elfCombine.pl + platform/csdk/<profile>/*.elf
  -> combined ELF
  -> objcopy S-record -> application LOD
  -> lodtool.py + platform/csdk/<profile>/*.lod
  -> combined flash LOD
```

`init/target.def` currently selects ASIC `8955`, flash model `flsh_spi32m`, and application model `csdk`. `platform/csdk/memd.def` supplies the user RAM/ROM limits. Both debug and release platform directories must contain exactly one ELF and one LOD image.

## Outputs

For `demo gpio`, the important artifacts are:

- `build/gpio/gpio.elf`: linked user application before platform ELF combination.
- `build/gpio/gpio.map`: symbol and memory map used for entry and capacity checks.
- `hex/gpio/gpio_BASE_csdk_<profile>.elf`: combined inspectable ELF.
- `hex/gpio/gpio_flash_<profile>.lod`: application LOD.
- `hex/gpio/gpio_B2130_<profile>.lod`: platform/application combined flashing image.

## Safety boundary

The maintained wrapper [`scripts/build-sdk.sh`](../scripts/build-sdk.sh) changes project selection only through Make variables. It deliberately avoids the historical `sed` operation in `build.sh`, so choosing a different example does not dirty the source tree. It validates the platform inputs and output cardinality before reporting success.

Compilation proves source/toolchain/linker integration. It does not prove modem registration, SIM operation, RF performance, GNSS reception, peripheral wiring, power stability, downloading, or boot behavior; those require target hardware tests.
