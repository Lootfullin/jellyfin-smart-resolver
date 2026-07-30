#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

if [[ "$(uname -s)" == "Darwin" ]]; then
    default_jellyfin_path="${HOME}/Library/Application Support/Jellyfin"
else
    default_jellyfin_path="/var/lib/jellyfin"
fi

jellyfin_path="${1:-${default_jellyfin_path}}"
"${script_dir}/package.sh"

plugin_path="${jellyfin_path}/plugins/Jellyfin Smart Resolver"
mkdir -p -- "${plugin_path}"
cp -- \
    "${repo_root}/publish/Jellyfin.Plugin.SmartResolver.dll" \
    "${plugin_path}/Jellyfin.Plugin.SmartResolver.dll"

printf 'Installed: %s\nRestart Jellyfin before using the new DLL.\n' "${plugin_path}"
