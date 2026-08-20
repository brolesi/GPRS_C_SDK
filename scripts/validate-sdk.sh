#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
csdtk_root="${CSDTK_ROOT:-}"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -n "$csdtk_root" ]] || fail 'set CSDTK_ROOT to the CSDTK package directory'
[[ -x "$csdtk_root/prepare-runtime-links.sh" ]] || fail "missing CSDTK compatibility helper: $csdtk_root/prepare-runtime-links.sh"

for command in bash tar make perl grep awk sha256sum; do
  command -v "$command" >/dev/null || fail "required host command not found: $command"
done

toolchain_root="$(bash "$csdtk_root/prepare-runtime-links.sh" --tool-root)"
runtime_lib_root="$(bash "$csdtk_root/prepare-runtime-links.sh" --runtime-lib)"
[[ -d "$toolchain_root" ]] || fail 'prepared toolchain root is missing'
[[ -d "$runtime_lib_root" ]] || fail 'prepared runtime library directory is missing'

export PATH="$toolchain_root/bin:$PATH"
export LD_LIBRARY_PATH="$runtime_lib_root:$toolchain_root/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

build_root="$(mktemp -d "${TMPDIR:-/tmp}/gprs-sdk-validation.XXXXXX")"
case "$build_root" in
  /tmp/gprs-sdk-validation.*) ;;
  *) fail "unexpected temporary build path: $build_root" ;;
esac

cleanup() {
  if [[ "${KEEP_BUILD:-0}" == 1 ]]; then
    printf 'KEEP_BUILD=1: retained validation workspace at %s\n' "$build_root"
  else
    rm -rf -- "$build_root"
  fi
}
trap cleanup EXIT

validate_profile() {
  local profile="$1"
  local source_root="$build_root/$profile"
  local log_file="$source_root/build/gpio_${profile}_build.log"
  local map_file="$source_root/build/gpio/gpio.map"
  local application_elf="$source_root/build/gpio/gpio.elf"
  local elf_file="$source_root/hex/gpio/gpio_BASE_csdk_${profile}.elf"
  local lod_file="$source_root/hex/gpio/gpio_B2130_${profile}.lod"
  local before_makefile_sha after_makefile_sha warning_count error_count

  mkdir -p "$source_root"
  tar --exclude=.git --exclude=build --exclude=hex -C "$repo_root" -cf - . | tar -C "$source_root" -xf -
  cd "$source_root"
  before_makefile_sha="$(sha256sum Makefile | awk '{print $1}')"
  bash scripts/build-sdk.sh demo gpio "$profile"
  after_makefile_sha="$(sha256sum Makefile | awk '{print $1}')"

  [[ "$before_makefile_sha" == "$after_makefile_sha" ]] || fail "$profile build changed the root Makefile"
  [[ -s "$log_file" ]] || fail "$profile build log is missing or empty"
  [[ -s "$map_file" ]] || fail "$profile map file is missing or empty"
  [[ -s "$application_elf" ]] || fail "$profile application ELF is missing or empty"
  [[ -s "$elf_file" ]] || fail "$profile ELF is missing or empty"
  [[ -s "$lod_file" ]] || fail "$profile LOD is missing or empty"

  warning_count="$(grep -Eic '(^|:)[[:space:]]*warning:|(^|[[:space:]])WARNING:' "$log_file" || true)"
  error_count="$(grep -Eic '(^|:)[[:space:]]*error:|(^|[[:space:]])ERROR:' "$log_file" || true)"
  [[ "$warning_count" == 0 ]] || fail "$profile build emitted $warning_count warning(s)"
  [[ "$error_count" == 0 ]] || fail "$profile build emitted $error_count error(s)"

  mips-elf-readelf -h "$elf_file" | grep -q 'Class:[[:space:]]*ELF32' || fail "$profile ELF is not ELF32"
  mips-elf-readelf -h "$elf_file" | grep -q "Data:.*little endian" || fail "$profile ELF is not little-endian"
  mips-elf-readelf -h "$elf_file" | grep -q 'Machine:[[:space:]]*MIPS R3000' || fail "$profile ELF machine is not MIPS R3000"
  mips-elf-readelf -S "$elf_file" >/dev/null || fail "$profile ELF section table is unreadable"
  mips-elf-readelf -l "$elf_file" >/dev/null || fail "$profile ELF program headers are unreadable"
  mips-elf-nm "$application_elf" | grep -q '[[:space:]]gpio_Main$' || fail "$profile application ELF does not contain gpio_Main"
  grep -q 'gpio_Main' "$map_file" || fail "$profile map does not contain gpio_Main"
  grep -q 'user_Init' "$map_file" || fail "$profile map does not contain user_Init"
  LC_ALL=C grep -q '^@' "$lod_file" || fail "$profile LOD has no address record"

  printf '%s_ELF bytes=%s sha256=%s\n' "${profile^^}" "$(wc -c < "$elf_file")" "$(sha256sum "$elf_file" | awk '{print $1}')"
  printf '%s_LOD bytes=%s sha256=%s\n' "${profile^^}" "$(wc -c < "$lod_file")" "$(sha256sum "$lod_file" | awk '{print $1}')"
  printf '%s_ENTRY %s\n' "${profile^^}" "$(mips-elf-readelf -h "$elf_file" | awk -F: '/Entry point address/{gsub(/^[[:space:]]+/, "", $2); print $2}')"
  printf '%s_WARNINGS %s\n' "${profile^^}" "$warning_count"
  printf '%s_ERRORS %s\n' "${profile^^}" "$error_count"
  printf '%s_MAKEFILE_SHA %s\n' "${profile^^}" "$after_makefile_sha"
}

validate_profile debug
validate_profile release
printf 'VALIDATION_OK profiles=debug,release project=demo/gpio\n'
