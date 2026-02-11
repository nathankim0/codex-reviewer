#!/bin/bash

# 플러그인 버전 자동 patch bump
# plugin.json과 marketplace.json의 버전을 동시에 올린다

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PLUGIN_JSON="$ROOT_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT_DIR/.claude-plugin/marketplace.json"

# 현재 버전 읽기
current_version=$(jq -r '.version' "$PLUGIN_JSON")

if [ -z "$current_version" ]; then
    echo "❌ 버전을 읽을 수 없습니다" >&2
    exit 1
fi

# semver patch bump (1.0.0 → 1.0.1)
IFS='.' read -r major minor patch <<< "$current_version"
new_version="$major.$minor.$((patch + 1))"

# plugin.json 업데이트
jq --arg v "$new_version" '.version = $v' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"

# marketplace.json 업데이트
jq --arg v "$new_version" '.plugins[0].version = $v' "$MARKETPLACE_JSON" > "$MARKETPLACE_JSON.tmp" && mv "$MARKETPLACE_JSON.tmp" "$MARKETPLACE_JSON"

echo "$current_version → $new_version"
