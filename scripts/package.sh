#!/usr/bin/env bash
set -euo pipefail

version="${1:-1.1.0}"
jellyfin_version="${2:-10.11.11}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
archive_name="Jellyfin.SmartResolver_${version}_jellyfin-${jellyfin_version}.zip"
artifacts="${repo_root}/artifacts"
publish="${repo_root}/publish"
stage="${artifacts}/package"

if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Version must use stable semantic versioning, for example 1.0.0." >&2
    exit 1
fi

if ! command -v dotnet >/dev/null 2>&1; then
    echo ".NET 9 SDK is required." >&2
    exit 1
fi
if [[ "$(dotnet --version)" != 9.* ]]; then
    echo ".NET 9 SDK is required." >&2
    exit 1
fi
if ! command -v zip >/dev/null 2>&1; then
    echo "The zip command is required." >&2
    exit 1
fi

for path in "${publish}" "${stage}"; do
    case "${path}" in
        "${repo_root}"/*) rm -rf -- "${path}" ;;
        *) echo "Refusing to clean a path outside the repository." >&2; exit 1 ;;
    esac
done

mkdir -p -- "${stage}"
dotnet restore "${repo_root}/Jellyfin.SmartResolver.sln"
dotnet build \
    "${repo_root}/Jellyfin.SmartResolver.sln" \
    -c Release --no-restore \
    -p:Version="${version}"
dotnet test "${repo_root}/Jellyfin.SmartResolver.sln" -c Release --no-build
dotnet publish \
    "${repo_root}/src/Jellyfin.Plugin.SmartResolver/Jellyfin.Plugin.SmartResolver.csproj" \
    -c Release --no-build -o "${publish}"

dll="${publish}/Jellyfin.Plugin.SmartResolver.dll"
test -f "${dll}"
cp -- "${dll}" "${stage}/"

cat > "${stage}/meta.json" <<EOF
{
  "category": "General",
  "changelog": "Plain-language settings, diagnostics, movie versions, multipart movies and deeper movie folders.",
  "description": "Safely finds media stored in extra folders and reads movie names from video files.",
  "guid": "c61d7897-a923-4a6d-9d4d-c6c911f28e73",
  "name": "Jellyfin Smart Resolver",
  "overview": "Finds series stored one folder deeper and reads movie names from video files.",
  "imageUrl": "https://raw.githubusercontent.com/Lootfullin/jellyfin-smart-resolver/main/assets/icon.svg",
  "owner": "Lootfullin",
  "targetAbi": "${jellyfin_version}.0",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "${version}.0",
  "status": "Active",
  "autoUpdate": false
}
EOF

mkdir -p -- "${artifacts}"
archive="${artifacts}/${archive_name}"
rm -f -- "${archive}" "${archive}.sha256"
(
    cd "${stage}"
    zip -q -X "${archive}" Jellyfin.Plugin.SmartResolver.dll meta.json
)

checksum="$(shasum -a 256 "${archive}" | awk '{print $1}')"
printf '%s  %s\n' "${checksum}" "${archive_name}" > "${archive}.sha256"
printf 'Package: %s\nSHA256: %s\n' "${archive}" "${archive}.sha256"
