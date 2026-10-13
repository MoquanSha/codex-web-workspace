---
name: weekend-city-trip
description: Comprehensive weekend city travel investigation skill for Chinese cities. Use this skill PROACTIVELY whenever the user wants to research a city for weekend or near-future (within 1 month) travel — including 小红书 activities, 演唱会/concerts, 集市/markets, 球赛/sports matches, 博物馆/museums, 优惠门票/discount tickets, 喜茶门店/Heytea locations, 美食街/food streets, city walk routes, 5A 景区/scenic areas, and 地铁路线/subway routes. Triggers on phrases like "调研XX城市"、"XX城市周末去哪"、"周末小旅游"、"XX城市旅游攻略"、"本周末/下周末去XX"、"XX城市近期活动"、"weekend trip to [city]"、"investigate [city]"、"城市调查". Search via anysearch CLI. All judgment, extraction, and writing done by the runtime agent (you) — no external LLM API calls. Generates text-only Markdown reports (no inline images; anysearch `search` does not return thumbnailUrl). Always invoke this skill when the user mentions researching any Chinese city for short-term travel, even if they don't explicitly ask for a "skill" or "攻略".
---

# 周末城市旅游攻略调研 Skill

基于 **anysearch WebSearch API** 的标准化城市旅游调研工作流,支持任意中国城市的本周末 / 下周末 / 未来一个月深度调研。

> **后端分工**:
> - 搜索 (Step 4-5) → **anysearch CLI**
> - 地点抽取 / 判断 / 清理 (Step 10) → **runtime agent 本体**(你读 markdown 自己干,**不调任何外部 LLM**)
> - 地图 (Step 10) → **高德 AMAP**
>
> **报告格式**: 纯文字版 (无内嵌图,改用 emoji + 表格 + 粗体强调)。anysearch `search` 不返回 thumbnailUrl。

覆盖 11 个调查方向:小红书近期活动、演唱会、集市、球赛、博物馆、优惠门票、喜茶门店、美食街、city walk、5A 景区、地铁路线。生成结构化的 Markdown 攻略,信源以权威媒体为主(腾讯新闻、网易、人民网、官方文旅、本地宝、行业媒体等)。

---

## 适用场景

✅ **适用**:
- "调研广州下周末有什么好玩"
- "上海本周末活动攻略"
- "成都未来一个月旅游调研"
- "北京周末小旅游"
- "我想下周末去杭州,帮我全面调查一下"

❌ **不适用**:
- 海外城市调研
- 长期旅居 / 移民调研(超过 1 个月)
- 单一深度主题(如只查某场演唱会票价 → 直接 WebSearch 即可)

---

## 前置准备

执行前必须确认 3 项:

| 项 | 说明 | 默认 |
|---|---|---|
| **Anysearch API key** | 用户提供 `as_sk-xxx` (anonymous 也可,QPS 低) | — |
| **目标城市** | 中文城市名(广州/上海/成都...) | — |
| **时间范围** | 本周末 / 下周末 / 未来一个月 / 具体日期 | 下周末 |
| 偏好(可选) | 亲子/情侣/独行/带娃 | 通用 |
| **报告格式** | 纯文字版(emoji + 表格 + 粗体) | 文字版 |
| **输出格式**(可选) | markdown / html / both | markdown |
| **工作目录**(可选) | 报告/地图输出目录,环境变量 `OUTPUT_DIR` | `D:/fireclaw-travel` |

如果用户没说时间范围,**默认下周末**(本周可能来不及准备)。

### API Key 配置

本 Skill 需要以下 API Key，推荐通过 `.env` 文件配置（已在 `.gitignore` 中排除，不会泄露）：

| 变量名 | 用途 | 申请地址 |
|--------|------|----------|
| `ANYSEARCH_API_KEY` | Anysearch WebSearch API（搜索调研） | https://anysearch.com/console/api-keys |
| `AMAP_KEY` | 高德 Web 服务 API（地理编码） | https://console.amap.com/dev/key/app（类型选「Web 服务」） |
| `AMAP_JS_KEY` | 高德 Web 端 JS API（浏览器加载地图底图） | https://console.amap.com/dev/key/app（类型选「Web 端(JS API)」 |
| `AMAP_SECURITY` | 高德安全密钥（与 JS API Key 配套） | 高德控制台 Key 详情页 |
| `OUTPUT_DIR` | 报告/地图输出目录（可选） | 默认 `D:/fireclaw-travel` |
| `VERBOSE` | 详细日志输出（可选，`1`/`true`/`yes`） | 默认关闭 |

**配置方式**:
```bash
# 方式 1: .env 文件（推荐，持久化）
cp .env.example .env
# 编辑 .env 填入你的 Key

# 方式 2: 环境变量（临时）
export ANYSEARCH_API_KEY="as_sk-xxx"
export AMAP_KEY="xxx"
export AMAP_JS_KEY="xxx"
export AMAP_SECURITY="xxx"
```

> **安全提醒**: 绝不要把 `.env` 文件或真实 Key 提交到版本库。`.env.example` 仅为模板，不含真实密钥。

---

## 工作流程(10 步法)

### Step 1: 时间锁定

算清楚用户的"本周末/下周末"对应的具体日期:
- 今天 = `{currentDate}`
- 本周末 = 即将到来的周六周日
- 下周末 = 下一个周六周日
- "未来一个月" = 今天起 30 天内

**关键洞察**:新闻文章发布时间 ≠ 活动举办时间。一篇 6/26 发布的文章可能在介绍 7/4 的活动。anysearch 没有 `freshness` 字段,改用 query 里加 `2026年7月`/`近期`/`本周末` 等关键词隐式表达"近期发布 + 介绍未来活动"的文章。

### Step 2: 用户确认

如果用户消息里已经包含城市 + 时间,直接进入 Step 3。
否则用 AskUserQuestion 确认。

### Step 3: TaskCreate + 工作目录

工作目录用 `$OUTPUT_DIR` 表示，默认为 `D:/fireclaw-travel`，可通过环境变量 `OUTPUT_DIR` 覆盖。
```
$OUTPUT_DIR/anysearch_{城市拼音}/
```

**变量约定**:
- `$OUTPUT_DIR` — 报告/地图输出目录（默认 `D:/fireclaw-travel`）
- `$SKILL_DIR` — 本 Skill 所在目录（即本文件所在目录，anysearch CLI 已内置在 `$SKILL_DIR/scripts/`）

TaskCreate 6 个任务(信息密度与执行效率的平衡点):
1. {城市}近期活动(活动/演唱会/集市/球赛/博物馆)
2. {城市}优惠门票(本地宝优惠 + 5A 景区)
3. {城市}喜茶热点(门店 + 购物中心)
4. {城市}美食街 + city walk
5. {城市}地铁路线(线网 + 关键站点出口)
6. 整合 {城市}纯文字报告

### Step 4: 写 query JSON 文件

按 `references/query_templates.md` 为每个调查方向写 query body（11 个 query 模板）。anysearch 字段简单，只有 `query` + `max_results`（1-10）：

```json
{"query":"广州 周末活动 展览 演出 市集 演唱会 2026年7月","max_results":10}
```

> 完整 query 体见 `references/query_templates.md`（11 模板）。

### Step 5: 并行批次执行（anysearch CLI）

anysearch `batch_search` 一次支持 1-5 并行，11 个 query 拆 3 批：

```bash
ANYSEARCH="python $SKILL_DIR/scripts/anysearch_cli.py"
DIR="$OUTPUT_DIR/anysearch_{城市拼音}"

# 批次 1（5 路并行：1a+1b+1c+1d+2a）
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 周末活动 展览 演出 市集 演唱会 2026年7月","max_results":10},
  {"query":"小红书 {CITY} 拍照 网红 打卡 同城活动 暑期","max_results":10},
  {"query":"{CITY} 7月 演唱会 集市 球赛 体育 周末去哪 最新","max_results":10},
  {"query":"{CITY} 博物馆 推荐 5A 景区 必去 打卡 2026","max_results":10},
  {"query":"{CITY} 景区 门票 优惠 暑期 学生 考生 特惠","max_results":10}
]' > "$DIR/r_batch1.json"

# 批次 2（4 路：3a+3b+4a+4b）
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 喜茶 旗舰店 打卡 购物中心 黑金店 2026","max_results":10},
  {"query":"{CITY} 喜茶 lab店 DP店 主题店 推荐","max_results":10},
  {"query":"{CITY} 美食街 推荐 夜市 区域 2026","max_results":10},
  {"query":"{CITY} city walk 路线 推荐 老城区 历史街区","max_results":10}
]' > "$DIR/r_batch2.json"

# 批次 3（2 路：5a+5b）
$ANYSEARCH batch_search --queries '[
  {"query":"{CITY} 地铁 线路图 2026 最新 主要区域","max_results":10},
  {"query":"{CITY}地铁 站点 出口 地标 商场","max_results":10}
]' > "$DIR/r_batch3.json"
```

**响应解析**（anysearch 返回 JSON-RPC `result.content[].text` 纯文本）：

```python
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

for f in ['r_batch1.json', 'r_batch2.json', 'r_batch3.json']:
    with open(f, encoding='utf-8') as fp:
        d = json.load(fp)
    for item in d.get('result', {}).get('content', []):
        if item.get('type') == 'text':
            print(f'==={f}===')
            print(item['text'][:2000])  # 截前 2000 字符预览
            break
```

### Step 6: 解析响应

anysearch 响应是 JSON-RPC 文本流，**无 `summary` / `data.images` 字段**。文本以 `--- 标题: ...\nURL: ...\n摘要: ...` 分隔。

整合报告时按这个分隔符切分，每个 result 块包含标题、URL、摘要三段。

> **注意**: anysearch 路径下**不嵌入外部图片**（`search` 响应无 `thumbnailUrl`）。报告改为纯文字版：emoji + 表格 + 粗体强调。

### Step 7: 整合文字报告(初稿)

按 `references/report_template.md` 的 10 节标准结构整合，输出到：
```
$OUTPUT_DIR/{城市}{时间}调查报告_Anysearch版.md
```

**注意**:这只是初稿,**不等于任务完成**。必须经过 Step 8 质量检查与迭代优化才能交付。

---

### Step 8: 质量检查与迭代优化(必做)

**报告生成 ≠ 任务完成**。必须按 `references/quality_check.md` 的清单检查并修复。

#### 8.1 自动检查(2 分钟)

用 python 脚本扫描初稿,5 大维度:
- **完整性**:11 调查方向 + 10 节结构是否齐全
- **准确性**:时间/地点/价格是否真实(演出日期在未来,地铁站存在)
- **丰富度**:每节信息密度是否达标
- **可执行性**:周末路线时间是否冲突,地铁换乘是否合理
- **信源多样性**:是否多源验证(关键信息 ≥ 2 个信源)

脚本模板见 `references/quality_check.md` 第 8 节。

#### 8.2 各节最低信息密度

| 章节 | 最低 | 优秀 |
|---|---|---|
| 演唱会/演出 | 3 场 | 5+ 场含时间/场馆/票价 |
| 博物馆 | 3 个 | 5+ 个含当前展览 |
| 5A 景区 | 2 个 | 4+ 个含票价/交通 |
| 优惠门票 | 3 个景区 | 5+ 个含原价/现价/规则 |
| 喜茶门店 | 2 家主题店 | 3+ 家含开业日期/产品 |
| 美食街 | 3 条 | 5+ 条含区域/代表店 |
| city walk | 1 条路线 | 2+ 条含节点/长度 |
| 地铁出口 | 2 个站点 | 4+ 站点含 A/B/C/D 编号 |
| 直达商场 | 5 个 | 10+ 个含地铁站 |

#### 8.3 错误识别与修复

| 问题类型 | 表现 | 修复方式 |
|---|---|---|
| **信息缺失** | 某节 < 最低要求 | 触发补查询(见 8.4) |
| **跨城市噪声** | 提到其他城市 | 删除条目,query 加城市前缀重查 |
| **过时数据** | 2018-2020 票价 | 标注"出行前请二次确认"或重查 |
| **虚假信息(摘要幻觉)** | 数字可疑、单源、矛盾 | 至少 2 个信源验证,否则删除 |
| **路线冲突** | 时间重叠/不可能换乘 | 重新设计路线 |

#### 8.4 补查询触发条件

**任一条件命中就触发补查询**(详见 `references/quality_check.md` 第 5 节):

🔴 **必补**(不补不能交付):
- 11 个调查方向有任何一个完全缺失
- 演唱会/演出章节 < 3 场
- 演出缺时间或场馆
- 优惠门票章节 < 3 个景区
- 跨城市噪声 > 30%

🟡 **建议补**(补了显著提升质量):
- 喜茶门店 < 2 家
- 美食街 < 3 条
- city walk 无具体路线
- 地铁出口细节 < 2 个站点
- 关键价格无信源支持

🟢 **可选**:
- 直达商场清单 < 5 个

#### 8.5 补查询执行

补查询走 anysearch batch_search (1-5 并行)，模板见 `references/quality_check.md` 第 6 节。常用模板：

```bash
# 演出不足
$ANYSEARCH batch_search --queries '[{"query":"{CITY} 演唱会 2026年7月 排期 时间 场馆 票价 大麦","max_results":10}]'

# 门票不足
$ANYSEARCH batch_search --queries '[{"query":"{CITY} 景区 门票 优惠 学生 暑期 {景区1} {景区2}","max_results":10}]'

# 喜茶门店不足
$ANYSEARCH batch_search --queries '[{"query":"{CITY} 喜茶 门店 地址 营业时间 推荐 {区域1}","max_results":10}]'

# 跨城市噪声严重 → 加强城市前缀
$ANYSEARCH batch_search --queries '[{"query":"{CITY} {CITY} {CITY} {主题} 必去 本地 仅限 {CITY}","max_results":10}]'
```

#### 8.6 迭代控制

- **最多 2 轮补查询**(防止无限循环)
- 每轮 ≤ 5 次(1 个批次)
- 总 API 调用 ≤ 16 次(初始 11 + 补救 5)
- 第 3 轮触发条件仍命中 → 标注"信息有限"交付,并在报告中说明

#### 8.7 二次检查

修复后**必须再次扫描**,确认所有 🔴 必补触发条件已解除。如仍有问题,进入第 2 轮迭代。

#### 8.8 修复优先级

1. **删除跨城市噪声条目**(错误信息会误导用户)
2. **删除过时数据**(2020 年前的票价/已闭店)
3. **补充缺失章节**(必补触发)
4. **补充低密度章节**(建议补触发)
5. **加二次确认安全声明**(无法验证的信息)

#### 8.9 交付

所有 🔴 必补触发条件解除后,告知用户:
- 文件路径
- 核心亮点
- API 调用统计(初始 N 次 + 补救 M 次 = 总 N+M 次)
- 已知限制(如有,如"地铁出口信息偏旧,建议二次确认")

---

### Step 9: HTML 输出(可选,条件触发)

**触发条件**:用户明确要求 HTML 格式(如"生成 html"、"给我网页版"、"输出 html 报告")。

**前置条件**:Step 8 质量检查必须已通过,Markdown 报告为最终交付版。

#### 9.1 检查 Python 依赖

```bash
python -c "import markdown" 2>&1 || pip install markdown pymdown-extensions
```

如不愿安装,脚本会自动降级到 `markdown2`,再降级到内置极简转换器(无需任何外部库)。

#### 9.2 执行转换

```bash
python $SKILL_DIR/scripts/md_to_html.py \
  "$OUTPUT_DIR/{城市}{时间}调查报告_Anysearch版.md"
# 默认输出同名 .html 文件,也可指定第二参数:
# python md_to_html.py input.md output.html
```

#### 9.3 HTML 特性

- **GFM 完整支持**:表格、代码块、引用块、有序/无序列表
- **中文字体优化**:苹方 / 微软雅黑 / 思源黑体 fallback
- **响应式布局**:手机 / 平板 / 桌面自适应
- **内嵌 CSS**:单文件可分享,无外部依赖
- **打印友好**:`@media print` 样式,可直接浏览器打印为 PDF
- **纯文字版样式**:emoji + 表格 + 粗体强调替代图片(因 anysearch 无 `thumbnailUrl` 响应)

#### 9.4 交付

告知用户:
- Markdown 源文件路径
- HTML 文件路径(本次新增)
- 推荐查看方式:浏览器打开,或打印为 PDF 分享

---

### Step 10: 地图面板生成(可选,条件触发)

**触发条件**:用户明确要求生成地图(如"生成地图"、"标注在地图上"、"地图版"、"mark on map")。

**前置条件**:Step 8 质量检查必须已通过,Markdown 报告为最终交付版。

**核心原则：地点抽取与判断全部由 runtime agent 本体（你）完成，不调任何外部 LLM API。**

#### 10.1 一键管线(build_map.sh)

可用 `build_map.sh` 一键执行完整管线(需要设置环境变量):

```bash
export AMAP_KEY="..."    # 高德 Web 服务 Key
export AMAP_JS_KEY="..." # 高德 Web 端 JS API Key
export AMAP_SECURITY="..." # 高德安全密钥

bash $SKILL_DIR/scripts/build_map.sh 金华 "未来一个月" \
  -m "$OUTPUT_DIR/金华未来一个月调查报告_Anysearch版.md"
```

该脚本自动执行以下 4 步,已完成步骤自动跳过:

```
Markdown 报告(.md)
   ↓ Step 1: agent 抽取地点  你(runtime agent)读 markdown,逐节识别真实地点,
   │                            排除食物名/活动名/描述,写 places.json
places.json
   ↓ Step 2: geocode.py        高德 REST 批量地理编码→ geo.json
places.geo.json
   ↓ Step 3: inject.py         模板替换→ 地图 HTML
{城市}地图_Anysearch版.html
   ↓ Step 4: validate_map.py     自动验证地图质量
```

> **Step 1 由 runtime agent 完成**:你直接读 markdown,逐节识别真实地点,排除食物名/活动名/广告文案等噪声,写 places.json。Step 2-4 才走脚本。

**核心决策**:坐标在**服务端预编码**写入 JSON。HTML 打开时只渲染,不调任何外部 API。
优势:
- 双击 HTML 即可,**不依赖 http 服务器**(file:// 也正常)
- 不受浏览器 QPS / 配额限制
- HTML 体积小、加载快、可离线分享

#### 10.2 高德 Key 要求(两种 Key,必须用户提供)

**Skill 不内置任何 Key**。用户需到 [高德开放平台](https://console.amap.com/dev/key/app) 申请以下两类 Key:

| 用途 | Key 类型 | 环境变量 | 说明 |
|---|---|---|---|
| HTML 地图底图加载 | **Web 端 (JS API)** | `AMAP_JS_KEY` | 应用类型选「Web 端(JS API)」 |
| JS API 安全密钥 | (与 JS API Key 配套) | `AMAP_SECURITY` | 2021-12-02 后申请的 Key 必须配置 |
| Python 服务端地理编码 | **Web 服务** | `AMAP_KEY` | 应用类型选「Web 服务」(REST 端点) |

**两类 Key 不能互通**:JS API Key 调 REST 会报 `USERKEY_PLAT_NOMATCH`,反之亦然。

**配置方式**(任选其一):

```bash
# 方式 A:bash / git-bash 环境变量(推荐,持久化到 shell 配置)
export AMAP_JS_KEY="用户提供的 JS API Key"
export AMAP_SECURITY="用户提供的安全密钥"
export AMAP_KEY="用户提供的 Web 服务 Key"

# 方式 B:Windows PowerShell
$env:AMAP_JS_KEY="..."
$env:AMAP_SECURITY="..."
$env:AMAP_KEY="..."

# 方式 C:单次命令前置(临时)
AMAP_KEY=xxx AMAP_JS_KEY=yyy AMAP_SECURITY=zzz python inject.py ...
```

**用户没提供 Key 时**:Skill 应当通过 `AskUserQuestion` 主动询问三类 Key,并指导用户到高德控制台申请;**不要编造或硬编码任何 Key 进 HTML**。

#### 10.3 4 步详细说明

```bash
SKILL="$SKILL_DIR"
REPORT="$OUTPUT_DIR/{城市}{时间}调查报告_Anysearch版.md"
CITY="{城市}"

# Step 1: agent 抽取地点（你来干，不调脚本）
# 读 $REPORT 全文，按章节识别真实地点：
#   - 景点 / 商场 / 餐厅老字号 / 公园 / 地铁站 / 演出场馆 / 喜茶门店 / 美食街
#   - 排除：食物名(牛肉丸/砂锅粥)、活动名(夏浪音乐节)、车次号、出口编号、纯描述
# 每个地点写一行 JSON：
#   {"name":"广济桥","category":"5A","note":"20元/人，傍晚过河拆桥"}
# 输出到 $REPORT.places.json，schema：
#   {"city":"潮州","places":[{"name","category","note"}]}

# Step 2: 服务端地理编码(需要 AMAP_KEY)
python "$SKILL/scripts/geocode.py" \
  "$REPORT.places.json" "$CITY"
# 输出: {城市}{时间}调查报告_Anysearch版.places.geo.json

# Step 3: 注入 HTML 模板(需要 AMAP_JS_KEY + AMAP_SECURITY)
# 地图中心自动从地点坐标的修剪中点计算,抗离群值
python "$SKILL/scripts/inject.py" \
  "$REPORT.places.geo.json" \
  "$OUTPUT_DIR/{城市}地图_Anysearch版.html" \
  "$CITY" "{时间范围如 2026/7/4-5}"
# 输出统一命名为 {城市}地图_Anysearch版.html(去掉时间前缀避免重复)

# Step 4: 质量验证
python "$SKILL/scripts/validate_map.py" \
  "$OUTPUT_DIR/{城市}地图_Anysearch版.html"
# 检查:文件大小、模板占位符、中心非北京回退、100% 编码、无 NaN、坐标在中国范围
```

**地点抽取的判断要点（runtime agent 工作清单）**：
1. **能上地图 = 真实地理坐标**：景点、商场、餐厅、公园、地铁站、演出场馆、酒店等
2. **不上地图 = 非地点**：食物名（鸭母捻）、活动名（灯光秀）、票价数字、车次号、出口编号、纯形容词
3. **同名消歧**：开元寺在泉州/潮州/福州都有，按报告上下文选对的那个
4. **补 known_coords**：`scripts/known_coords.json` 有预置坐标可直接复用，agent 读它做 fast-path

**结果**:双击 `{城市}地图_Anysearch版.html` 即可在浏览器打开,所有标记立即可见。

#### 10.4 11 类配色系统

地图标记按调查方向分 11 类,采用**水滴形 + 字母**标记,鼠标悬停显示标签:

| 类型 | 字母 | 颜色 | 说明 |
|---|---|---|---|
| 演唱会 | C | 🔴 #d32f2f | 演唱会/音乐会 |
| 球赛 | S | 🟣 #7b1fa2 | 体育赛事 |
| 集市 | M | 🟡 #f9a825 | 集市/夜市 |
| 博物馆 | U | 🔵 #1565c0 | 博物馆/展览 |
| 5A景区 | 5 | 🟠 #e65100 | 5A/4A 景区 |
| 喜茶 | H | 🩷 #ec407a | 喜茶门店 |
| 美食街 | F | 💮 #ad1457 | 美食街/老字号 |
| City Walk | W | 🌊 #00838f | City Walk 路线 |
| 购物中心 | L | 💜 #4527a0 | 商场 |
| 地铁站 | D | ⚪ #546e7a | 地铁关键站 |
| 优惠门票 | T | 🟢 #2e7d32 | 优惠门票 |

#### 10.5 已实现的核心交互

- ✅ **分类筛选 pill**:点击切换显示/隐藏类别
- ✅ **搜索框**:实时过滤卡片(名称/地址/备注)
- ✅ **双向联动**:点击卡片 → 地图飞至 + 打开 InfoWindow;点击标记 → 高亮卡片
- ✅ **自动视野适配**:启动时自动 `setFitView` 包含所有标记
- ✅ **图例**:右下角显示 11 类配色对照
- ✅ **响应式**:手机纵向布局 / 桌面横向布局
- ✅ **NaN 坐标保护**:无坐标的地点不参与地图飞至,提示用户
- ✅ **中心合理性检查**:地图中心为北京但地点在别处时显示警告横幅

#### 10.6 已知问题与修复记录

| 问题 | 根因 | 修复 |
|---|---|---|
| 部分城市中心在北京 | inject.py CENTERS 字典缺失该城市 | 改为从地点坐标**修剪中点**自动计算(抗离群值) |
| 重复文件混乱 | 管线无统一入口,各步骤独立执行 | `build_map.sh` 一键管线,自动清理旧文件 |
| 地图中心偏离 | min/max 中点受离群坐标影响 | 改用**修剪中点**(去除两端 10% 后取中点) |
| HTML 中 TRIP_DATA 无法解析 | JS 对象非 JSON(无引号 key、注释) | validate_map.py 增加 JS→JSON 转换器 |
| **坐标城市错乱**(潮州开元寺→泉州) | known_coords 中"开元寺"存的是泉州坐标;AMAP city 参数只是提示而非硬过滤;geocode.py 不校验返回 city 字段 | ① 删除 known_coords 中多城市共有地名(AMBIGUOUS_NAMES 集);② geocode.py Layer B:校验 AMAP 响应 city 字段,不匹配则重试;③ Layer C:坐标中国范围检查;④ inject.py 防御性过滤(>3° 偏离中心则隐藏) |

#### 10.7 交付

告知用户:
- Markdown 报告路径
- 地图 HTML 路径(统一为 `{城市}地图_Anysearch版.html`)
- 地点总数 + 编码成功率(100% 预编码)
- 地图验证结果(通过/警告/失败)

---

## 调查的 11 个方向

详细 query 模板见 `references/query_templates.md`。

| # | 方向 | query 数 | 时间过滤方式 | 关键响应字段 |
|---|---|---|---|---|
| 1 | 小红书近期活动 | 1-2 | query 关键词 `近期`/`本周末`/`7月` | `result.content[].text` |
| 2 | 演唱会 | 1 | query 关键词 `7月 最新 排期` | 同上 |
| 3 | 集市 / 市集 | 1 | query 关键词 `近期 市集` | 同上 |
| 4 | 球赛 | 1 | query 关键词 `本周末 球赛` | 同上 |
| 5 | 博物馆 | 1 | 无时间过滤,query 关键词 `2026 推荐` | 同上 |
| 6 | 优惠门票(本地宝) | 1 | query 关键词 `暑期 学生` | 同上 |
| 7 | 喜茶门店 + 购物中心 | 2 | 无时间过滤,query 关键词 `2026 旗舰店` | 同上 |
| 8 | 美食街 | 1 | 无时间过滤 | 同上 |
| 9 | city walk 路线 | 1 | 无时间过滤 | 同上 |
| 10 | 5A 景区 | 1 | 无时间过滤 | 同上 |
| 11 | 地铁路线 | 2 | 无时间过滤 | 同上 |

**总计 11-13 次 API 调用**(anysearch `batch_search` 一次 1-5 并行,3 批次内可完成)。

---

## Anysearch API 用法速查

### 端点(默认走 anysearch CLI,无需直接调 HTTP)

```bash
# Python 入口(已内置在 SKILL_DIR/scripts/)
python $SKILL_DIR/scripts/anysearch_cli.py

# 常用子命令
python .../anysearch_cli.py search "广州 周末活动" --max_results 10
python .../anysearch_cli.py batch_search --queries '[{"query":"A"},{"query":"B"}]'
python .../anysearch_cli.py get_sub_domains --domain travel
python .../anysearch_cli.py extract --url https://example.com
```

### 必选/可选参数

| 参数 | 必选 | 推荐值 |
|---|---|---|
| `query` | ✅ | 中文长尾,4 要素:地点+主题+时效+品类 |
| `max_results` | 可选 | 1-10(默认 10) |
| `domain` / `sub_domain` | 可选 | 垂直域(金融/学术/法律/健康/旅游/...) |
| `sub_domain_params` | 可选 | 垂直域参数(如股票代码) |

### 响应结构(JSON-RPC 2.0)
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {"type": "text", "text": "--- 标题: ...\nURL: ...\n摘要: ...\n\n--- 标题: ..."}
    ]
  }
}
```

### 字段说明
- 响应是 `result.content[0].text` 纯文本(多结果以 `--- 标题: ...` 分隔)
- 每段包含：标题、URL、摘要三部分
- **无 `summary` AI 摘要**、**无 `datePublished`**、**无 `siteName`**、**无 `thumbnailUrl`**
- 整合报告时按 `--- 标题: ...\nURL: ...\n摘要: ...` 切分

> 完整踩坑与决策树见 `references/anysearch_notes.md`。

---

## 关键踩坑(Top 5)

详细版 + 决策树见 `references/anysearch_notes.md`。

1. **query 关键词隐式表达时效**：anysearch 无 freshness 参数，靠 `2026年7月`/`近期`/`本周末` 关键词
2. **不要堆超过 5 个 query 在一个 batch_search**：上限就是 5
3. **跨城市噪声**：query 强加城市名前缀（`{CITY} {CITY} {主题}`）
4. **召回数量不是质量指标**：5-7 条高质量文本结果优于 15 条低质量，不要为追求召回量浪费 quota
5. **anonymous QPS 极低**：建议带 `ANYSEARCH_API_KEY`

---

## 报告结构(10 节标准)

详细模板见 `references/report_template.md`。

```
〇、一图速览(表格,11 类标记 + 核心亮点)
一、下周末 + 月度活动清单(演唱会/集市/球赛/漫展/博物馆/5A)
二、优惠门票(本地宝 + 5A 景区)
三、喜茶门店热点(LAB/DP/PINK 等主题店)
四、美食街
五、city walk 路线
六、地铁路线(含 5A 景区 + 商场直达)
七、周末组合路线(A/B/C 三条主题路线)
八、时效可靠性说明
九、API 调用统计
十、引用源
```

每节用 emoji (🏛️ / 🎤 / 🎪 / ⚽ ...) + 表格 + 粗体小标题提升可读性(替代原图片版式)。

---

## 跨城市差异预警

不同城市的 anysearch 索引覆盖存在差异,需要在设计 query 时留余量:

| 维度 | 可能现象 | 应对 |
|---|---|---|
| 冷门城市召回量 | 因城市而异(5-10 条波动) | 接受现状,query 多加区域关键词 |
| 喜茶主题店类型 | 各城市定位不同(LAB/DP/PINK/Cake Lab) | 从 `text` 字段里识别关键词 |
| 地铁出口数据新旧 | 长尾信息文章可能偏旧 | 接受(出口编号基本不变)+ 报告加二次确认提示 |
| 中文旅游垂直域 | 中文旅游域参数 (`domain=travel`) 不一定收录所有城市 | 默认 `general` 域,垂直域作为补充 |
| anonymous QPS | 无 key 时频繁 429 / 慢响应 | 强烈建议带 `ANYSEARCH_API_KEY` |

**核心原则**:**召回数量不是质量指标**,5-7 条高质量文本结果优于 15 条低质量。不要为追求召回量重试浪费 quota。

---

## 失败状态码

anysearch 是 JSON-RPC 2.0,主要看 `error.code` + `error.message`:

| 错误 | 原因 | 对策 |
|---|---|---|
| `error.code: -32600` | Invalid Request | 检查 JSON-RPC payload |
| `error.code: -32601` | Method not found | 确认 `tools/call` 参数 |
| `error.code: -32602` | Invalid params | 检查 query / max_results 类型 |
| `error.code: -32603` | Internal error | 重试,或换 query 关键词 |
| `error.code: -32000` (自定义) | Quota exhausted | 配置 `ANYSEARCH_API_KEY` 或等额度恢复 |
| `error.code: -32001` (自定义) | Invalid API key | 换 key |
| HTTP 429 | 频率超限 | `sleep 60` 重试 |
| HTTP 5xx | 服务端异常 | 退避重试 3 次后报错 |

---

## 参考文件指引

何时读哪个 reference:

- **写 query 时** → 读 `references/query_templates.md`(11 个方向的 query body 模板)
- **整合报告时** → 读 `references/report_template.md`(10 节结构 + 表格示例)
- **遇到踩坑时** → 读 `references/anysearch_notes.md`(踩坑 + 决策树 + 状态码表)
- **报告写完后** → 读 `references/quality_check.md`(质量检查 + 补查询迭代,**必做**)
- **用户要 HTML 时** → 用 `scripts/md_to_html.py`(三档优先级转换,内嵌 CSS,响应式)
- **用户要地图时** → 读 `references/map_generation.md`(四步生成 + 模板注入,**Step 10**)

---

## 一句话总结

**anysearch CLI + query 关键词时效控制 + 任务间数据复用 + 5+4+2 批次 + 跨城市标准化 SOP + 质量检查迭代 + runtime agent 接管地点抽取 = 11-15 次调用产出 20KB+ 高质量纯文字报告,覆盖 11 个调查方向。**

记住 7 个关键节点:**先算时间 → 设计 query → 5 路 batch_search 并行 → 按模板整合 → 质量检查迭代**(Step 8 不可跳过)→ **HTML 输出**(Step 9 条件触发)→ **地图面板**(Step 10 条件触发，地点抽取由你 runtime agent 自己干)。
