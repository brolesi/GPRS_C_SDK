[![中文](https://img.shields.io/badge/中文-文档-blue)](VALIDATION.zh.md)

# Validation Evidence

## Scope and environment

- Date: 2026-08-20.
- Host: Windows with WSL2 Ubuntu 22.04.
- Toolchain: the repository's documented GPRS_CSDTK MIPS GCC 4.4.2 package, prepared with `prepare-runtime-links.sh`.
- Target: the checked-in `demo/gpio`, built independently in debug and release profiles.
- Method: [`scripts/validate-sdk.sh`](../scripts/validate-sdk.sh), using fresh ASCII-only `/tmp` copies for each profile.

## Recorded result

| Check | Debug | Release |
| --- | ---: | ---: |
| Build exit status | Pass | Pass |
| Compiler warnings / errors | 0 / 0 | 0 / 0 |
| Reported ROM use | 688 / 1,048,576 bytes | 688 / 1,048,576 bytes |
| Reported RAM use | 48 / 1,048,576 bytes | 48 / 1,048,576 bytes |
| Combined ELF size | 12,499,972 bytes | 12,108,072 bytes |
| Combined ELF entry | `0x88010010` | `0x88010010` |
| Combined LOD size | 5,456,784 bytes | 5,456,784 bytes |
| Combined LOD SHA-256 | `1d63b9d781744f8c560107c04868691a4b65163145058b6ed4fa01b8c50e076e` | `9c9dac14ad82c4f3800c15a26d989109db1e4c196ea6c85c82d71806ae3382d8` |

Both combined images were readable as ELF32 little-endian MIPS R3000 files. The application ELF and map contained `gpio_Main`; the map contained `user_Init`. The generated LOD files contained address records. The root `Makefile` SHA-256 remained `8fdc7a5e481bef0056684988b6796d79c234021e23d5f332f65e033e73b43629` before and after both builds.

The combined ELF contains build-directory debug paths, so its byte hash can vary when validation uses a newly named temporary directory. The LOD hashes above were stable across repeated runs and are the better reproducibility signal for this legacy build.

## Reproduce

```bash
CSDTK_ROOT=/path/to/GPRS_CSDTK/CSDTK bash scripts/validate-sdk.sh
```

The script fails immediately if a command is missing, a platform input is ambiguous, Make changes the source `Makefile`, a build warning/error is detected, expected artifacts are missing, ELF metadata is invalid, entry symbols are absent, or the LOD lacks address records.

## Not validated

No device was connected. Flashing, boot, UART logs, SIM detection, GSM/GPRS registration, calls/SMS, GNSS, RF behavior, peripherals, FOTA, and sustained power behavior remain unverified. A release decision must include target-board testing with the intended module revision, power supply, SIM/operator, antenna, and regional network.
