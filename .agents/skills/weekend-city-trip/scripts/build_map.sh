#!/bin/bash
# ============================================================
# build_map.sh — 一键地图生成管线(Step 2-4)
# 用法:
#   bash build_map.sh <城市> <日期范围> -m <markdown.md> [-p <places.json>] [-o <output.html>]
#
# 示例:
#   bash build_map.sh 金华 "2026年7月(未来一个月)" \
#     -m "D:/fireclaw-travel/金华未来一个月调查报告_Anysearch版.md" \
#     -p "D:/fireclaw-travel/金华未来一个月调查报告_Anysearch版.places.json" \
#     -o "D:/fireclaw-travel/金华地图_Anysearch版.html"
#
# 注意:Step 1(agent 抽取地点)由 runtime agent 手动完成,不在本脚本范围。
#       本脚本接收现成的 places.json,执行 Step 2-4。
#
# 环境变量(必需):
#   AMAP_KEY      高德 Web 服务 API Key (用于 geocode.py)
#   AMAP_JS_KEY   高德 Web 端 JS API Key (用于 inject.py)
#   AMAP_SECURITY 高德安全密钥 (用于 inject.py)
# 可选:
#   OUTPUT_DIR   报告/地图输出目录(默认 D:/fireclaw-travel)
# ============================================================
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$SKILL_DIR/scripts"

# 加载 .env 文件(如存在),已设置的环境变量不覆盖
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

OUTPUT_DIR="${OUTPUT_DIR:-D:/fireclaw-travel}"

CITY=""
DATE_RANGE=""
MD_FILE=""
PLACES_FILE=""
OUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--markdown) MD_FILE="$2"; shift 2 ;;
    -p|--places)   PLACES_FILE="$2"; shift 2 ;;
    -o|--output)   OUT_FILE="$2"; shift 2 ;;
    *)
      if [[ -z "$CITY" ]]; then CITY="$1"
      elif [[ -z "$DATE_RANGE" ]]; then DATE_RANGE="$1"
      else echo "未知参数: $1"; exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$CITY" ]]; then
  echo "❌ 用法: bash build_map.sh <城市> <日期范围> -m <markdown.md> -p <places.json> [-o <output.html>]"
  exit 1
fi

# 自动推断 Markdown 路径(如未指定)
if [[ -z "$MD_FILE" ]]; then
  MD_FILE=$(ls "$OUTPUT_DIR"/*${CITY}*调查报告_Anysearch版.md 2>/dev/null | head -1 || true)
  if [[ -z "$MD_FILE" ]]; then
    echo "❌ 未找到 ${CITY} 的 Markdown 报告文件,请用 -m 指定"
    exit 1
  fi
fi

if [[ ! -f "$MD_FILE" ]]; then
  echo "❌ 文件不存在: $MD_FILE"
  exit 1
fi

# 自动推断 places.json 路径(Step 1 由 agent 已生成)
if [[ -z "$PLACES_FILE" ]]; then
  BASE="${MD_FILE%.md}"
  PLACES_FILE="${BASE}.places.json"
fi

if [[ ! -f "$PLACES_FILE" ]]; then
  echo "❌ places.json 不存在: $PLACES_FILE"
  echo "   Step 1 (agent 抽取地点) 尚未完成。请先由 runtime agent 读 Markdown 生成 places.json。"
  exit 1
fi

GEO_JSON="${PLACES_FILE%.json}.geo.json"

if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="${OUTPUT_DIR}/${CITY}地图_Anysearch版.html"
fi

echo "=============================================="
echo "  🏗️  地图生成管线: $CITY  (Step 2-4)"
echo "  📄  Markdown: $MD_FILE"
echo "  📍  places:   $PLACES_FILE"
echo "  🗺️  输出地图: $OUT_FILE"
echo "  📅  日期范围: ${DATE_RANGE:-未指定}"
echo "=============================================="

# ---- Step 2: geocode.py ----
echo ""
echo "【Step 2/4】地理编码..."
if [[ -f "$GEO_JSON" ]]; then
  ALL_OK=$(python -c "
import json
with open('$GEO_JSON', encoding='utf-8') as f:
    data = json.load(f)
ok = sum(1 for p in data if p.get('geocoded'))
print('all' if ok == len(data) else f'{ok}/{len(data)}')
")
  if [[ "$ALL_OK" == "all" ]]; then
    echo "  ⏭️  跳过: $GEO_JSON 已全部编码"
  else
    echo "  🔄  部分未编码 ($ALL_OK),重新执行..."
    python "$SCRIPTS_DIR/geocode.py" "$PLACES_FILE" "$CITY"
  fi
else
  python "$SCRIPTS_DIR/geocode.py" "$PLACES_FILE" "$CITY"
fi

# ---- Step 3: inject.py ----
echo ""
echo "【Step 3/4】生成地图 HTML..."

# 清理旧地图文件,避免重复
OLD_MAPS=$(ls "$OUTPUT_DIR"/*${CITY}*地图_Anysearch版.html 2>/dev/null || true)
for old in $OLD_MAPS; do
  if [[ "$old" != "$OUT_FILE" ]]; then
    rm -f "$old"
    echo "  🗑️ 清理旧地图: $old"
  fi
done

python "$SCRIPTS_DIR/inject.py" "$GEO_JSON" "$OUT_FILE" "$CITY" "$DATE_RANGE"

# ---- Step 4: validate_map.py ----
echo ""
echo "【Step 4/4】验证地图..."
VALIDATION_OUTPUT=$(python "$SCRIPTS_DIR/validate_map.py" "$OUT_FILE" 2>&1) || true
echo "$VALIDATION_OUTPUT"

if echo "$VALIDATION_OUTPUT" | grep -q "❌"; then
  echo ""
  echo "⚠️  验证发现问题,请检查以上输出"
  exit 1
fi

echo ""
echo "=============================================="
echo "  ✅ 地图生成完成!"
echo "  🗺️  $OUT_FILE"
echo "=============================================="
