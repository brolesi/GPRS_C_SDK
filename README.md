[![中文](https://img.shields.io/badge/中文-README-blue)](README.zh.md)

# Ai-Thinker GPRS C SDK

C SDK for developing applications on Ai-Thinker A9/A9G modules and compatible RDA8955-based hardware. It includes peripheral, networking, telephony, GNSS, storage, audio, and cloud examples under [`demo/`](demo/).

> **Lifecycle notice:** this is a legacy 2G/GPRS SDK. The last repository update and published SDK releases are historical. Check local 2G network availability, hardware revision, and release notes before starting a new product. Existing release tags use the project's historical `V2.xxx` convention rather than Semantic Versioning.

## Supported hardware

- A9: quad-band GSM/GPRS module.
- A9G: A9 features plus GPS/BDS.
- A9/A9G development board (Pudding board).
- Other RDA8955 designs may work, but must be verified on their target hardware.

The module can draw peak current near 2 A. Use a suitable 3.4–4.2 V supply on `VBAT`, or the development board's regulated 5 V input. The board USB connector is a USB 1.1 device interface; downloading and serial debugging require a USB-to-UART adapter connected to `HST_TX` and `HST_RX`.

## Repository map

| Path | Purpose |
| --- | --- |
| `app/` | Application template; the application entry is `app_Main()` |
| `demo/` | Runnable examples such as GPIO, UART, MQTT, GPS, SMS, and file-system use |
| `init/` | SDK-to-application startup bridge |
| `libs/` | Shared source libraries |
| `include/` | Public SDK headers |
| `platform/` | Build rules, linker scripts, platform ELF/LOD images, and libraries |
| `scripts/` | Non-mutating build wrapper and repeatable validation |

See [Code entry](docs/CODE_ENTRY.md) and [Architecture](docs/ARCHITECTURE.md) for the source-backed execution and build flow.

## Requirements

- Linux or WSL2. The repository has been validated on Ubuntu 22.04 under WSL2.
- GNU Make, Bash, Perl, and standard Unix utilities.
- The matching legacy MIPS toolchain from [GPRS_CSDTK](https://github.com/Ai-Thinker-Open/GPRS_CSDTK).
- The checked-in `platform/csdk/debug` and `platform/csdk/release` platform files. Release archives are available on the [GitHub Releases page](https://github.com/Ai-Thinker-Open/GPRS_C_SDK/releases).

The old compiler is sensitive to non-ASCII and Windows-mounted paths. For the most predictable result, keep both repositories in an ASCII-only Linux filesystem path. The validation script automatically builds from an isolated ASCII `/tmp` path.

## Build

Prepare the GPRS_CSDTK compatibility runtime and expose the toolchain:

```bash
export CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK
export TOOLCHAIN_ROOT="$(bash "$CSDTK_ROOT/prepare-runtime-links.sh" --tool-root)"
export RUNTIME_LIB_ROOT="$(bash "$CSDTK_ROOT/prepare-runtime-links.sh" --runtime-lib)"
export PATH="$TOOLCHAIN_ROOT/bin:$PATH"
export LD_LIBRARY_PATH="$RUNTIME_LIB_ROOT:$TOOLCHAIN_ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

Build the GPIO example or the application template:

```bash
bash scripts/build-sdk.sh demo gpio debug
bash scripts/build-sdk.sh demo gpio release
bash scripts/build-sdk.sh app debug
```

The wrapper selects `PROJECT_PATH` on the Make command line and does **not** edit the root `Makefile`. Generated files are written to `build/<project>/` and `hex/<project>/`. The historical `build.sh` is retained for compatibility, but it rewrites line 15 of `Makefile`; use the wrapper for routine work.

## Repeatable validation

Run both clean GPIO profiles in isolated copies:

```bash
CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK bash scripts/validate-sdk.sh
```

The check builds debug and release, rejects compiler warnings/errors, verifies that `Makefile` was not changed, inspects the generated ELF32 little-endian MIPS images, confirms `gpio_Main` and `user_Init`, and checks the combined LOD records. See [Validation evidence](docs/VALIDATION.md) for the recorded result and explicit hardware-test limits.

## Documentation and support

- [SDK documentation repository](https://github.com/Ai-Thinker-Open/GPRS_C_SDK_DOC)
- [Online documentation](https://ai-thinker-open.github.io/GPRS_C_SDK_DOC/en/)
- [Examples](demo/)
- [Issue tracker](https://github.com/Ai-Thinker-Open/GPRS_C_SDK/issues)

This repository is licensed under the [MIT License](LICENSE). Bug fixes and documentation improvements are welcome through pull requests.
