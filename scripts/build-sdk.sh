#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  bash scripts/build-sdk.sh app [debug|release]
  bash scripts/build-sdk.sh demo <name> [debug|release]

The MIPS toolchain must already be available on PATH. This wrapper does not
rewrite the repository Makefile, unlike the historical build.sh entry point.
EOF
}

[[ $# -ge 1 ]] || { usage; exit 2; }

case "$1" in
  app)
    [[ $# -le 2 ]] || { usage; exit 2; }
    project_path='app'
    project_name='app'
    profile="${2:-debug}"
    ;;
  demo)
    [[ $# -ge 2 && $# -le 3 ]] || { usage; exit 2; }
    [[ "$2" =~ ^[A-Za-z0-9._-]+$ ]] || fail 'demo name may contain only letters, digits, dot, underscore, and hyphen'
    project_path="demo/$2"
    project_name="$2"
    profile="${3:-debug}"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

[[ "$profile" == debug || "$profile" == release ]] || fail "unsupported build profile: $profile"
[[ -d "$repo_root/$project_path" ]] || fail "project directory not found: $project_path"
[[ -f "$repo_root/platform/csdk/memd.def" ]] || fail 'platform/csdk/memd.def is missing'

for command_name in make tee grep awk sha256sum mips-elf-gcc mips-elf-ld mips-elf-objcopy; do
  command -v "$command_name" >/dev/null 2>&1 || fail "required command not found: $command_name"
done

shopt -s nullglob
platform_elf=("$repo_root/platform/csdk/$profile"/*.elf)
platform_lod=("$repo_root/platform/csdk/$profile"/*.lod)
(( ${#platform_elf[@]} == 1 )) || fail "expected exactly one platform ELF in platform/csdk/$profile"
(( ${#platform_lod[@]} == 1 )) || fail "expected exactly one platform LOD in platform/csdk/$profile"

export SOFT_WORKDIR="$repo_root"
export PROJ_NAME="$project_name"

mkdir -p "$repo_root/build"
log_file="$repo_root/build/${project_name}_${profile}_build.log"
jobs="${BUILD_JOBS:-}"
if [[ -z "$jobs" ]]; then
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')"
fi
[[ "$jobs" =~ ^[1-9][0-9]*$ ]] || fail "BUILD_JOBS must be a positive integer: $jobs"

printf 'Building project=%s path=%s profile=%s jobs=%s\n' "$project_name" "$project_path" "$profile" "$jobs"
cd "$repo_root"
make -j"$jobs" CT_RELEASE="$profile" PROJECT_PATH="$project_path" 2>&1 | tee "$log_file"

map_file="$repo_root/build/$project_name/$project_name.map"
[[ -s "$map_file" ]] || fail "map output is missing or empty: $map_file"
output_dir="$repo_root/hex/$project_name"
[[ -d "$output_dir" ]] || fail "output directory is missing: $output_dir"

output_elf=("$output_dir"/*_"$profile".elf)
output_lod=("$output_dir/${project_name}_B"*_"$profile".lod)
(( ${#output_elf[@]} == 1 )) || fail "expected exactly one generated $profile ELF in hex/$project_name"
(( ${#output_lod[@]} == 1 )) || fail "expected exactly one generated $profile LOD in hex/$project_name"

ram_total="$(awk '/USER_RAM_SIZE/{print $2; exit}' platform/csdk/memd.def)"
rom_total="$(awk '/USER_ROM_SIZE/{print $2; exit}' platform/csdk/memd.def)"
rom_start="$(awk '/__rom_start = \./{print $1; exit}' "$map_file")"
rom_rw_start="$(awk '/__user_rw_lma = \./{print $1; exit}' "$map_file")"
ram_start="$(awk '/__user_rw_start = \./{print $1; exit}' "$map_file")"
ram_rw_end="$(awk '/__user_rw_end = \./{print $1; exit}' "$map_file")"
ram_end="$(awk '/__user_bss_end = \./{print $1; exit}' "$map_file")"

if [[ -n "$ram_total" && -n "$rom_total" && -n "$rom_start" && -n "$rom_rw_start" && -n "$ram_start" && -n "$ram_rw_end" && -n "$ram_end" ]]; then
  ram_used=$((ram_end - ram_start))
  rw_size=$((ram_rw_end - ram_start))
  rom_used=$((rom_rw_start - rom_start + rw_size))
  printf 'ROM used: %d / %d bytes\n' "$rom_used" "$((rom_total))"
  printf 'RAM used: %d / %d bytes\n' "$ram_used" "$((ram_total))"
fi

printf 'ELF %s bytes=%s sha256=%s\n' "${output_elf[0]#$repo_root/}" "$(wc -c < "${output_elf[0]}")" "$(sha256sum "${output_elf[0]}" | awk '{print $1}')"
printf 'LOD %s bytes=%s sha256=%s\n' "${output_lod[0]#$repo_root/}" "$(wc -c < "${output_lod[0]}")" "$(sha256sum "${output_lod[0]}" | awk '{print $1}')"
printf 'Build completed successfully. Log: %s\n' "${log_file#$repo_root/}"
