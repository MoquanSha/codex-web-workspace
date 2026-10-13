# 沙漠泉的 Codex 网页工作区

```bash
# 1. 先验证现有配置是否完整，无需联网或安装
python3 scripts/validate_bundle.py

# 2. 首次设置或缺少依赖时，创建仓库虚拟环境并验证技能元数据
bash scripts/setup.sh

# 3. 需要文档处理或飞书 CLI 时才增加对应工具；已安装则跳过
bash scripts/setup.sh --documents --lark

# 4. 完成后验证结构与元数据；飞书另行检查云端登录状态
.venv/bin/python scripts/validate_bundle.py --yaml
tools/lark/node_modules/.bin/lark-cli auth status --verify
```

**1.1 用途与隐私**

这个私有仓库让 Codex 网页端沿用本地沟通习惯、个人画像、研究叙事和技能工作流。它包含个人背景，仅供用户授权的私有环境使用。不要把整个仓库公开发布。

**1.2 在网页创建环境**

在 Codex 的创建云端环境窗口选择 `MoquanSha/codex-web-workspace`。列表没有时先刷新，再通过“配置访问权限”让已连接的 GitHub 应用访问这个仓库。选择“开始设置”，把下面这段话发给设置对话。

> 请按本仓库 AGENTS.md、memory/INDEX.md、memory/PROFILE.md 准备我的个人云端工作区。先运行 python3 scripts/validate_bundle.py；通过后运行 bash scripts/setup.sh --documents --lark。不要把账号凭据写入仓库，不要自动修改个人画像。保留仓库技能目录 .agents/skills。检查读取完整画像、技能发现、文档库导入和 lark-cli 命令能否正常工作。飞书登录尚未授权就标为待授权，不把它说成已连接。环境可用范围保持 Only me。给出实际验证结果后再完成环境发布。

设置成功后发布环境，开始一个新任务。这里“发布环境”只用于保存云端配置，不改变 GitHub 私有可见性。若 pip/npm 下载失败，检查环境是否允许相应包管理器域名；若 Python 缺少 venv，请让设置对话安装相应系统包后重试。所有工具均在已有检查通过时跳过重复安装。

**1.3 如何保持个人连续性**

根目录 `AGENTS.md` 会要求先读画像入口；相关任务再加载两份完整画像。摘要明确了后来更正的作者顺序和研究进展，完整文件保留历史。默认中文、简洁回答、技术术语翻译、运行顺序讲解、论文精读标准和材料证据边界均由同一入口约束。

**1.4 技能与工具**

`.agents/skills` 保存可被仓库发现的技能，`environment/skill-catalog.json` 提供完整检索目录。重复安装的同一目录优先采用本机 `.agents/skills` 版本；去重记录和文件校验值见 `environment/source-manifest.json`。

`skill-library/plugins` 保存插件的技能资料。资料存在不等于相应服务已登录或工具可调用。见 `environment/CAPABILITIES.md`。本地模型偏好位于 `environment/local-preferences.json`，需要在网页界面选择可用模型与推理强度。

**1.5 日常文件与同步**

项目产物放 `projects/`，详细记录放 `records/`，短期延续信息放 `memory/daily/`。原始证件与成绩单不随配置上传；临时提供的个人原件可放被 Git 忽略的 `materials/`。

这次迁移为一次导入。网页的新对话读取仓库文件，不会自动继承本机聊天历史；稳定更新需要用户授权、保留历史并提交到私有仓库。重要成果应提交保存，不能仅依赖云端会话缓存。

**1.6 新任务验收**

在发布后的新对话发送下列请求，检查它实际读取了文件，而不只猜测用户情况。

> 读取本仓库的规则和个人画像，简短说明我的研究方向、写作习惯，以及 Learning to Hand Back 和 ForesightSafety-VLA 应如何准确描述。列出来源文件和日期。再定位导师调查与论文精读技能，运行配置验证脚本。不要修改任何个人档案。

合格结果应区分已知事实、历史状态、试点证据和缺失原件，能找到两份画像、相关技能和精读模板。配置脚本通过只证明文件包可用；上述新对话才用于检验网页端实际加载和行为。连接第三方服务与完整视频渲染需分别验收。
