# anysearch API 踩坑清单 + 决策树

> 使用 **anysearch WebSearch API** 做城市调研时的常见踩坑与应对方案。
> anysearch 是 `weekend-city-trip` skill 的唯一搜索后端。
>
> 遇到任何异常,**先来这里查决策树**。

---

## Top 8 踩坑速查表

| # | 坑名 | 严重度 | 触发条件 | 应对 |
|---|---|---|---|---|
| 1 | `max_results` 超出 1-10 范围 | ⭐⭐⭐⭐⭐ | `--max_results 15` | 严格 1-10,默认 10 |
| 2 | 无 `summary` AI 摘要 | ⭐⭐⭐⭐ | 报告整合阶段 | 改用 `text` 字段里的 snippet 段落,降级一档信息密度 |
| 3 | 无 `freshness` 字段 | ⭐⭐⭐⭐ | 旧 query 含 `oneMonth`/`oneWeek` | 改用 query 关键词 `2026年7月`/`本周末`/`近期` 隐式表达 |
| 4 | 无 `thumbnailUrl` / 无图 | ⭐⭐⭐ | 旧 SKILL.md 模板要求 `![](url)` | 报告改为纯文字版 (emoji + 表格 + 粗体强调) |
| 5 | `batch_search` 超过 5 个 query | ⭐⭐⭐⭐ | 一次塞 6+ query | 拆成 2+ 次 `batch_search`,每批 1-5 |
| 6 | anonymous 模式 QPS 极低 | ⭐⭐⭐⭐ | 无 `ANYSEARCH_API_KEY` | 申请 key (https://anysearch.com/console/api-keys) |
| 7 | 垂直域未先调 `get_sub_domains` | ⭐⭐⭐ | 旅行/财经/学术等有 vertical 域 | 先 `get_sub_domains --domain travel` 查子域 + 必填参数 |
| 8 | JSON-RPC 错误码语义 | ⭐⭐ | `error.code` 不在 -32600 ~ -32603 | 见下方状态码表;`Quota exhausted` → 配 key / 等待 |

---

## 决策树(快速应对)

### 调用前的预防

```
我有 Anysearch Key 吗?
├─ 是 → 写入 .env (ANYSEARCH_API_KEY=as_sk-...)
└─ 否 → 可以走 anonymous,但 QPS 低,小流量 OK,大批量必加 key

我想查什么主题?
├─ 旅行/演唱会/景点/餐厅
│   └─ ✅ 有 vertical 域: --domain travel,先用 get_sub_domains 查子域
├─ 财经/股票/财报
│   └─ ✅ 有 vertical 域: --domain finance,同上
├─ 通用/城市调研
│   └─ 用 general 域 (默认),无需 get_sub_domains
└─ 不确定
    └─ 走 hybrid: batch_search 混 1 general + N vertical

我想 batch 多少个 query?
├─ 1-5 → batch_search 一次跑完
├─ 6-10 → 拆 2 次 batch_search (5+5 或 4+6)
└─ 11+ → 拆 3 次以上,记录每批响应

时效应怎么表达?
├─ anysearch 无 freshness 字段
└─ 改用 query 关键词:
    - 本周/周末活动 → "本周末 2026年7月"
    - 暑期活动 → "暑期 7月 8月"
    - 长期资源 (博物馆/5A) → "推荐 2026 必去"
    - 不限时效 → 直接主题词,不加时间
```

### 响应解析

```python
import json
with open("r_batch1.json", encoding="utf-8") as fp:
    d = json.load(fp)
# anysearch 是 JSON-RPC 2.0,响应路径:
# d["result"]["content"][0]["text"]  → 纯文本
# 内部格式:
#   --- 标题: ...
#   URL: https://...
#   摘要: ...
#   (空行)
#   --- 标题: ...
text = d["result"]["content"][0]["text"]
# 按 "--- 标题:" 切分成多条结果
items = [seg for seg in text.split("--- 标题:") if seg.strip()]
# items[0] 通常是开头空,跳过
for seg in items[1:]:
    # 解析: 首行 = 标题,下一行 = URL,再下一行 = 摘要
    lines = seg.strip().split("\n", 2)
    if len(lines) >= 3:
        title = lines[0].strip()
        url = lines[1].replace("URL:", "").strip()
        summary = lines[2].replace("摘要:", "").strip()
        # ... 提取逻辑
```

### 报告整合时(纯文字版)

anysearch `search` / `batch_search` **不返回 thumbnailUrl**,报告统一改为:
- 表格代替图片对比
- emoji (🎤 🏛️ 🎪 ⚽ 🩷 🍜 🌊) 代替分类图标
- **粗体**强调关键名称
- 每节 `> 📌 一句话:` 总结要点

---

## 状态码表(JSON-RPC 2.0)

| 错误 / HTTP 码 | 含义 | 对策 |
|---|---|---|
| `error.code: -32600` | Invalid Request | JSON-RPC payload 结构错,检查 `jsonrpc` / `id` / `method` 字段 |
| `error.code: -32601` | Method not found | `tools/call` 参数错,确认 tool name 拼写 (search / batch_search / extract / get_sub_domains) |
| `error.code: -32602` | Invalid params | query 为空 / `max_results` 越界 (1-10) / `domain` 不在白名单 |
| `error.code: -32603` | Internal error | 后端异常,简化 query 重试,或换关键词 |
| `error.code: -32000` | Quota exhausted | 配 `ANYSEARCH_API_KEY` 或等额度恢复;`auto_registered` 字段可能含新 key,需用户确认后存盘 |
| `error.code: -32001` | Invalid API key | key 格式错或失效,重新申请 |
| HTTP 429 | 频率超限 | `sleep 60` 重试,或减少并行度 |
| HTTP 5xx | 服务端异常 | 退避重试 3 次 (`sleep 5/15/45`) 后报错 |

---

## anysearch 字段与限制

| 维度 | 现状 | 影响 / 应对 |
|---|---|---|
| 字段 | `query` + `max_results` (1-10) | 旧模板的 `summary`/`count`/`freshness` 全部失效 |
| `summary` (AI 摘要) | ❌ 无,只有 search engine snippet | 信息密度降一档,补查一轮 |
| `datePublished` | ❌ 无,只能从 URL/文本推断 | 时效判断要靠 query 关键词隐式表达 |
| `siteName` | ❌ 无,从 URL 推断 | 报告里只能写 "来源 URL" |
| `freshness` | ❌ 无 | 改用 query 关键词 `2026年7月`/`本周末`/`近期` 隐式表达 |
| `include`/`exclude` | ❌ 无 | 改 query 加 "本地宝" 等关键词 |
| `data.images` | ❌ 无 `thumbnailUrl` | 报告纯文字版 |
| `batch_search` 并行 | 1-5 query | 超过 5 拆批 |
| LLM 端点 | ❌ 无 | 地点抽取/判断全部由 runtime agent 本体完成,不调任何外部 LLM |
| 配额提示 | 响应 `auto_registered` 字段自动签发新 key | 配额耗尽时自动续 key (需用户确认后存盘) |

---

## anysearch 响应格式(原文示例)

```text
--- 标题: 2026广州演唱会排期表(最新)
URL: https://example.com/gz-concerts-2026
摘要: 广州2026年7月-8月演唱会汇总,涵盖周杰伦、张学友、陈奕迅等歌手,
时间地点票价一文全览,大麦网同步售票...

--- 标题: 广州周末去哪玩?7月最强攻略
URL: https://example.com/gz-weekend-2026
摘要: 广州市文旅局推荐,本周末展览、演出、市集、city walk 全清单,
地铁直达,免费/优惠门票信息...

--- 标题: 广州博物馆暑假特展
URL: https://example.com/gz-museum-summer
摘要: 广东省博物馆、广州博物馆、南越王博物院三大馆 7 月特展,
开放时间、门票、地铁线路汇总...
```

**注意**:
- 每条结果用 `--- 标题:` 起头,空行分隔
- 字段顺序:**标题 → URL → 摘要**
- 摘要可能含换行,建议按 `split("--- 标题:")` 切分后取首 3 行
- 无 `siteName` / `datePublished` / `images` 等附加字段

---

## 常用子域速查(get_sub_domains 输出)

| 域 | 常用子域 | 必填参数示例 |
|---|---|---|
| `travel` | `travel.destination` / `travel.event` | `city=广州,date=2026-07` |
| `finance` | `finance.quote` / `finance.market` | `type=stock,symbol=AAPL,cn_code=` |
| `social_media` | `social_media.x` / `social_media.reddit` | (一般无需参数) |
| `general` | (无子域) | — |

**`travel` 域调研城市的 query 模板**:
```bash
# 1. 先查子域
python anysearch_cli.py get_sub_domains --domain travel

# 2. 用子域 + 必填参数
python anysearch_cli.py search "广州 周末活动 7月" \
  --domain travel --sub_domain travel.event \
  --sdp city=广州,date=2026-07
```

**注意**:任何域 `--sdp` 含 `(required)` 标记的参数必须传,无值也要传空字符串 (如 `cn_code=`)。漏传会触发 -32602 Invalid params。

---

## .env 配置注意事项

1. **BOM 坑**:Windows Notepad 写 `.env` 会带 UTF-8 BOM,anysearch CLI 已用 `utf-8-sig` 自动剥离,但其他读 `.env` 的脚本要兼容。
2. **优先级**:`--api_key` CLI > `.env` 文件 > 系统环境变量 > anonymous。
3. **换行**:`.env` 每行 `KEY=VALUE`,无空格;带空格的值要 `"VALUE"`。
4. **单搜索 key**:`ANYSEARCH_API_KEY=as_sk-...` 用于所有搜索;没有其他外部 LLM key 需要。

---

## 一句话总结

**anysearch = JSON-RPC 2.0 + `query` + `max_results 1-10` + `batch_search` 1-5 并行 + 无图无 summary,改 query 关键词隐式表达时效,响应是 `result.content[].text` 纯文本(按 `--- 标题:` 切分)。地点抽取/判断由 runtime agent 本体完成,不调任何外部 LLM。**

详细 API 用法见 `$SKILL_DIR/SKILL.md` 与 `$SKILL_DIR/scripts/anysearch_cli.py`（CLI 已内置在本 skill 中）。
