# 11 个调查方向的 Query 模板(anysearch 版)

> 搜索后端:**anysearch CLI**(`batch_search` 1-5 并行)
> 文件名约定:`r_batch{1-3}.json`(batch 响应)
> 整合报告文件名:`{城市}{时间}调查报告_Anysearch版.md`

---

## anysearch 字段说明

| 字段 | 取值 | 备注 |
|---|---|---|
| `query` | 中文长尾 | 4 要素:地点+主题+时效+品类 |
| `max_results` | 1-10 | 默认 10 |
| `domain` | `general`(默认)/ `travel` / `finance` 等 | 垂直域可选 |
| `sub_domain` | 垂直域子项 | 需先调 `get_sub_domains` |
| `sub_domain_params` | 域参数 | 必填项无值也要传空字符串 |

**响应字段**（在 `result.content[].text` 内,以 `--- 标题: ...\nURL: ...\n摘要: ...` 切分）:
- 标题 / URL / 摘要 三段
- **无** `siteName` / `datePublished` / `summary` AI 摘要 / `thumbnailUrl`

**时效应(关键)**:anysearch 无 freshness 字段,改用 query 关键词:

| 需求 | query 关键词 |
|---|---|
| 本周活动 | `本周末 2026年7月` |
| 本月活动 | `2026年7月 7月 近期` |
| 暑期 | `暑期 7月 8月` |
| 长期资源(博物馆/5A) | `推荐 2026 必去` |
| 不限时效 | 直接主题词 |

---

## 调查方向与 query 总览

| 任务 | 调查方向 | batch 批次 | anysearch max_results | 时效关键词 |
|---|---|---|---|---|
| 1a | 近期活动(主力) | 批次 1 | 10 | `2026年7月 周末活动 演出 市集` |
| 1b | 小红书 / 网红打卡 | 批次 1 | 10 | `暑期 拍照 打卡` |
| 1c | 演唱会 + 集市 + 球赛(最新) | 批次 1 | 10 | `7月 最新 排期` |
| 1d | 博物馆 + 5A 景区 | 批次 1 | 10 | `推荐 2026 必去` |
| 2a | 优惠门票 | 批次 1 | 10 | `暑期 学生 优惠` |
| 3a | 喜茶旗舰店 | 批次 2 | 10 | `2026 旗舰店 购物中心` |
| 3b | 喜茶主题店(LAB/DP/PINK) | 批次 2 | 10 | (不限时效) |
| 4a | 美食街 | 批次 2 | 10 | (不限时效) |
| 4b | city walk 路线 | 批次 2 | 10 | (不限时效) |
| 5a | 地铁路网 | 批次 3 | 10 | `2026 最新` |
| 5b | 地铁出口细节 | 批次 3 | 10 | (不限时效) |

**总计 11 个 query,3 批次并行(5 + 4 + 2)**。

---

## 任务 1:近期活动(4 次 query,合并为批次 1)

### q1a — 周末活动主力

```json
{"query":"{CITY} 周末活动 展览 演出 市集 演唱会 {MONTH}","max_results":10}
```

**示例**(目标=广州,月份=2026年7月):
```json
{"query":"广州 周末活动 展览 演出 市集 演唱会 2026年7月","max_results":10}
```

### q1b — 小红书 / 网红打卡

> ⚠️ **重要踩坑（2026-07 修复）**：原 query `小红书 {CITY} 拍照 网红 打卡 同城活动` 把"小红书"当作内容风格关键词，召回的 10 条全是知乎/Instagram/facebook 等二手内容，**0 条来自 xiaohongshu.com**。改为 `site:xiaohongshu.com {CITY} {主题}` 后能稳定召回 40 条真实小红书内容（达人/品牌官方主页，含笔记标题列表）。
>
> **召回限制说明**：anysearch 主要索引达人主页（`/user/profile/xxx`）和旧版问答页（`/mobile/question/xxx`），**不索引搜索结果页（`/explore/search?xxx`）和单条笔记**（小红书反爬严格）。但主页里的笔记标题列表本身就是高密度情报（活动预告、近期主题、品牌上新等）。

```json
{"query":"site:xiaohongshu.com {CITY} 周末活动 {MONTH} 演出 展览 同城","max_results":10}
```

**示例**:
```json
{"query":"site:xiaohongshu.com 广州 周末活动 7月 演出 展览 同城","max_results":10}
```

**推荐拆为 2-4 路并行**（提升召回覆盖）：
```json
{"query":"site:xiaohongshu.com {CITY} 周末 同城活动 打卡 拍照 推荐","max_results":10}
{"query":"site:xiaohongshu.com {CITY} {主题1} 探店 推荐","max_results":10}
```

**反例（不要再这样写）**:
- ❌ `小红书 {CITY} 拍照 网红 打卡` — "小红书"被当风格词，召回非小红书站点
- ❌ `xiaohongshu.com/explore {CITY}` — `/explore` 让 anysearch 联想"探索活动"，召回豆瓣同城
- ❌ `xiaohongshu.com {CITY}` 不加 `site:` — 召回主流媒体，小红书主页空内容

**正例**:
- ✅ `site:xiaohongshu.com {CITY} 周末活动 {MONTH} 演出` — 严格域名过滤
- ✅ `site:xiaohongshu.com {CITY} {达人名/品牌名}` — 直查达人主页

### q1c — 演唱会 + 集市 + 球赛(最新一周)

```json
{"query":"{CITY} {MONTH} 演唱会 集市 球赛 体育 比赛 周末去哪 最新","max_results":10}
```

**示例**:
```json
{"query":"广州 7月 演唱会 集市 球赛 体育 比赛 周末去哪 2026 最新","max_results":10}
```

### q1d — 博物馆 + 5A 景区(长期资源)

```json
{"query":"{CITY} 博物馆 推荐 5A 景区 必去 打卡 2026","max_results":10}
```

**示例**:
```json
{"query":"广州 博物馆 推荐 5A 景区 必去 打卡 2026","max_results":10}
```

---

## 任务 2:优惠门票(1 次 query,合并为批次 1)

### q2a — 暑期优惠门票

```json
{"query":"{CITY} 景区 门票 优惠 暑期 {MONTH} 学生 考生 特惠","max_results":10}
```

**示例**:
```json
{"query":"广州 景区 门票 优惠 暑期 2026 长隆 广州塔 白云山","max_results":10}
```

**关键提醒**:
- ❌ **不要用 `include` 域名过滤**:anysearch 不支持
- ✅ **改用 query 加城市前缀 + 具体景区名**(如长隆/广州塔/白云山)
- ✅ 想要本地宝内容,query 里加 "本地宝" 关键词,让 anysearch 自然召回

---

## 任务 3:喜茶热点(2 次 query,合并为批次 2)

### q3a — 旗舰店 + 购物中心

```json
{"query":"{CITY} 喜茶 旗舰店 打卡 购物中心 黑金店 2026","max_results":10}
```

**示例**:
```json
{"query":"广州 喜茶 旗舰店 打卡 太古汇 天环广场 正佳 黑金店 2026","max_results":10}
```

### q3b — 主题店盘点(LAB/DP/PINK)

```json
{"query":"{CITY} 喜茶 lab店 DP店 主题店 推荐","max_results":10}
```

**示例**:
```json
{"query":"广州 喜茶 lab店 DP店 主题店 推荐","max_results":10}
```

---

## 任务 4:美食街 + city walk(2 次 query,合并为批次 2)

### q4a — 美食街

```json
{"query":"{CITY} 美食街 推荐 夜市 {区域1} {区域2} {区域3} {区域4} 2026","max_results":10}
```

**示例**:
```json
{"query":"广州 美食街 推荐 夜市 北京路 上下九 西关 体育西 2026","max_results":10}
```

### q4b — city walk 路线

```json
{"query":"{CITY} city walk 路线 推荐 老城区 历史街区 拍照 2026","max_results":10}
```

**示例**:
```json
{"query":"广州 city walk 路线 推荐 老城区 历史街区 拍照 2026","max_results":10}
```

---

## 任务 5:地铁路线(2 次 query,合并为批次 3)

### q5a — 线网总览

```json
{"query":"{CITY} 地铁 线路图 2026 最新 {主要区域1} {主要区域2} {主要区域3}","max_results":10}
```

**示例**:
```json
{"query":"广州 地铁 线路图 2026 最新 天河 海珠 越秀 白云 番禺","max_results":10}
```

### q5b — 关键站点出口

```json
{"query":"{CITY}地铁 站点 出口 {地标1} {地标2} {地标3} {地标4}","max_results":10}
```

**示例**:
```json
{"query":"广州地铁 站点 出口 长隆 广州塔 北京路 体育西 珠江新城","max_results":10}
```

---

## 完整执行批次(anysearch batch_search)

```bash
ANYSEARCH="python $SKILL_DIR/scripts/anysearch_cli.py"
DIR="$OUTPUT_DIR/anysearch_{城市拼音}"
mkdir -p "$DIR"

# 批次 1(5 路并行,任务 1+2 主力)
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 周末活动 展览 演出 市集 演唱会 {MONTH}","max_results":10},
  {"query":"小红书 {CITY} 拍照 网红 打卡 同城活动 暑期","max_results":10},
  {"query":"{CITY} {MONTH} 演唱会 集市 球赛 体育 周末去哪 最新","max_results":10},
  {"query":"{CITY} 博物馆 推荐 5A 景区 必去 打卡 2026","max_results":10},
  {"query":"{CITY} 景区 门票 优惠 暑期 {MONTH} 学生 考生","max_results":10}
]' > "$DIR/r_batch1.json"

# 批次 2(4 路,任务 3+4)
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 喜茶 旗舰店 打卡 购物中心 黑金店 2026","max_results":10},
  {"query":"{CITY} 喜茶 lab店 DP店 主题店 推荐","max_results":10},
  {"query":"{CITY} 美食街 推荐 夜市 区域 2026","max_results":10},
  {"query":"{CITY} city walk 路线 推荐 老城区 历史街区","max_results":10}
]' > "$DIR/r_batch2.json"

# 批次 3(2 路,任务 5)
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 地铁 线路图 2026 最新 主要区域","max_results":10},
  {"query":"{CITY}地铁 站点 出口 地标 商场","max_results":10}
]' > "$DIR/r_batch3.json"
```

**响应解析**(anysearch 是 JSON-RPC `result.content[].text` 纯文本):

```python
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

for f in ['r_batch1.json', 'r_batch2.json', 'r_batch3.json']:
    with open(f, encoding='utf-8') as fp:
        d = json.load(fp)
    for item in d.get('result', {}).get('content', []):
        if item.get('type') == 'text':
            text = item['text']
            items = [seg for seg in text.split('--- 标题:') if seg.strip()]
            print(f'==={f} ({len(items)} 条)===')
            for seg in items[:10]:
                lines = seg.strip().split('\n', 2)
                if len(lines) >= 3:
                    title = lines[0].strip()
                    url = lines[1].replace('URL:', '').strip()
                    summary = lines[2].replace('摘要:', '').strip()[:150]
                    print(f'  - {title}')
                    print(f'    {url}')
                    print(f'    {summary}')
            break
```

---

## 城市关键词速查表(填入 query 提高召回)

| 城市 | 购物中心 | 美食区 | 地标 | 5A 景区 |
|---|---|---|---|---|
| **广州** | 太古汇、正佳、天河城、天环、K11、东方宝泰、广百、万菱汇、igc、花城汇 | 北京路、上下九、西关、体育西 | 广州塔、白云山、珠江夜游 | 长隆、白云山、西樵山(近) |
| **深圳** | 万象天地、海岸城、壹方城、海雅缤纷城、深业上城、卓悦中心、欢乐港湾 | 东门、华强北、上梅林、八卦岭、盐田、车公庙 | 世界之窗、欢乐谷、平安金融中心 | 世界之窗、欢乐谷、东部华侨城、观澜湖 |
| **上海** | 南京路、淮海路、新天地、静安寺、徐家汇、五角场 | 城隍庙、田子坊、云南南路、吴江路、虹泉路 | 外滩、东方明珠、迪士尼 | 迪士尼、东方明珠、上海野生动物园 |
| **北京** | 三里屯、王府井、西单、SKP、国贸 | 簋街、南锣鼓巷、王府井、护国寺、牛街 | 故宫、长城、天坛 | 故宫、长城、颐和园、天坛 |
| **成都** | 太古里、IFS、万象城、银泰中心 | 锦里、宽窄巷子、玉林、华兴 | 大熊猫基地、宽窄巷子 | 大熊猫基地、青城山、都江堰 |

---

## query 设计的 4 要素法则

每个 query 必须包含:

1. **地点**:城市名(强制开头,可重复 2-3 次)
2. **主题**:活动/门票/喜茶/美食街/地铁/city walk/博物馆/5A 等
3. **时效**:本周末 / 下周末 / 7月 / 暑期 / 2026
4. **品类**:演唱会/展览/市集 / 旗舰店/LAB/DP / 北京路/上下九

**反例**:
- ❌ `广州 活动`(太宽泛,召回杂)
- ❌ `周末活动`(缺地点,召回全国)
- ❌ `广州`(只一个词,无法定位主题)

**正例**:
- ✅ `广州 周末活动 展览 演出 市集 演唱会 2026年7月`(全要素)
- ✅ `广州 喜茶 lab店 DP店 主题店 推荐`(主题明确)
- ✅ `广州 博物馆 推荐 5A 景区 必去 打卡 2026`(品类清晰)

---

## 高级技巧

### 跨城市噪声防御

anysearch 可能召回其他城市的同名结果。query 重复城市名 2-3 次:

```json
{"query":"{CITY} {CITY} 演唱会 7月 必看 攻略 本地仅{CITY}","max_results":10}
```

### 数据复用(任务间)

任务 1(活动)的 snippet 里通常已包含 60-70% 的门票信息,**任务 2 可以直接复用任务 1 的数据**,只在缺口处追加 1 次 query。

### 失败降级

任何响应 `result.content[0].text` 长度 < 200 字符或 `error` 字段非空:
- 简化 query(去掉品类关键词)
- 改 query 关键词组合
- 改 `max_results` 到 5 看是否更精准

### 垂直域(可选)

旅行类主题用 `travel` 域可拿到更精准结果:

```bash
python anysearch_cli.py search "广州 周末活动 7月" \
  --domain travel --sub_domain travel.event \
  --sdp city=广州,date=2026-07
```

先 `get_sub_domains --domain travel` 查子域和必填参数。

---

## 一句话总结

**11 个调查方向 → 11 个 anysearch query → `batch_search` 1-5 并行 → 3 批次(5+4+2) → 30-60 秒完成数据采集 → 按 10 节模板整合纯文字报告 (emoji + 表格 + 粗体强调,无图)。**
