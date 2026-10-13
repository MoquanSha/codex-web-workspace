#!/bin/bash
# ============================================================
# anysearch_search.sh — anysearch CLI 薄包装
# 用途: 避免 SKILL.md 大段 python 命令;自动加载 .env
#
# 用法(透传 anysearch_cli.py 所有子命令):
#   bash anysearch_search.sh search "广州 周末活动" --max_results 5
#   bash anysearch_search.sh batch_search --queries '[{"query":"A"},{"query":"B"}]'
#   bash anysearch_search.sh get_sub_domains --domain travel
#   bash anysearch_search.sh extract --url https://example.com
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
# CLI 已内置在本 skill 的 scripts/ 目录下
ANYSEARCH_DIR="${ANYSEARCH_DIR:-$SKILL_DIR}"

# 加载 .env(已设置的环境变量不覆盖)
_load_dotenv() {
  local env_file
  for env_file in "$SKILL_DIR/.env" "$PWD/.env"; do
    if [[ -f "$env_file" ]]; then
      while IFS='=' read -r key val || [[ -n "$key" ]]; do
        key="$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        val="$(echo "$val" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//;s/^'\''//;s/'\''$//')"
        [[ -z "$key" || "$key" == \#* ]] && continue
        if [[ -z "${!key:-}" ]]; then
          export "$key=$val"
        fi
      done < "$env_file"
    fi
  done
}
_load_dotenv

# 选择 CLI(Python 优先,Node 兜底)
if command -v python >/dev/null 2>&1; then
  PY=python
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  echo "❌ 未找到 python/python3,请安装 Python 3.6+ 或使用 Node/PowerShell CLI" >&2
  exit 2
fi

CLI="$SKILL_DIR/scripts/anysearch_cli.py"
if [[ ! -f "$CLI" ]]; then
  echo "❌ 未找到 anysearch CLI: $CLI" >&2
  echo "   请确认 weekend-city-trip/scripts/anysearch_cli.py 存在" >&2
  exit 2
fi

# 透传所有参数
exec "$PY" "$CLI" "$@"
