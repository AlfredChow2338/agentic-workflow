# Agentic Workflow

This project is the configuration files for my agentic workflow for customised coding work.

## Useful commands

1. Symbolic link different agent harness to the same AGENTS.md (eg. Claude, Cursor)

```sh
ln -s ~/AGENTS.md ~/.claude/CLAUDE.md

ln -s ~/AGENTS.md ~/.cursor/AGENTS.md
```

## 影片筆記：Agentic Engineering 工作流程

來源：[Assembling a crew of coding agents](https://www.youtube.com/watch?v=iQyg-KypKAA)（前 Meta/Microsoft/Atlassian L8 首席工程師分享）

核心比喻：你是船長，agent 是船員。目標是招募、訓練、指揮一群 agent，同時把自己從「寫 code 的人」升級成「工程主管」。

### 工具鏈
- **終端機為中心**：WezTerm（跨平台、Lua 可配置）+ tmux（分割窗格、多 session、持久化、可跨裝置連線同一 session）+ Neovim（雙手不離鍵盤，維持 flow）
- **Agent framework 保持中立**：常用 Claude Code / Codex CLI / 其他開源 agent，刻意不綁死單一 framework，因為模型/agent 生態變化太快
- **語音輸入**：本地跑 Whisper 轉錄，比打字快約 3 倍，只有網址/檔案路徑等內容才用打字

### Memory 與 Skills（agent 的 onboarding）
- **全域 memory file**（`~/.claude/CLAUDE.md`，symlink 到 `AGENTS.md`）：只放跨專案都適用的個人偏好，保持極簡（影片中只有 27 行），因為這份內容會被塞進「每一個」session 的 system prompt
- **專案級 memory file**（repo 根目錄的 `CLAUDE.md`/`AGENTS.md`）：記錄專案背景、目錄結構、術語、關鍵元件如何運作、如何做端對端測試、慣例。**不要一次手寫完**，而是每次抓到 agent 做錯事就糾正它，並把這次學習存進這份檔案，讓錯誤不會重複發生
- **Skills**：只在特定情境才需要的資訊（例如「如何跑 e2e 測試」）應該從 memory file 抽成 skill，利用 progressive disclosure（session 啟動時只載入一行描述，真正用到才讀取完整內容），避免每次都燒 token
- **警告**：不要隨便安裝網路上的 skill，即使 star 數很高。理由有二：(1) skill 可以指示 agent 在你機器上執行任意操作，有洩漏 API key/憑證的風險；(2) 許多熱門 skill 從未經過嚴謹評測——影片作者用 benchmark 測試一個 17.7 萬 star 的 skill repo，結果讓 agent 多花 5% token 且表現反而更差

### Agent-friendly 工具設計
- 把 agent 當一等公民來設計工具介面：例如用 GitHub CLI 存取 GitHub，比用 GitHub MCP server 省 3 倍 token、延遲減半
- 用 token-efficient 的輸出格式（非 JSON）可省約 40% token
- 重點：**給 agent 工具前，先評估這個工具本身的 token/延遲效率**，這會大幅影響 agent 的產出效率

### 規劃階段
- 複雜任務先進規劃階段，把選項渲染成 HTML（沿用專案既有的 design system）讓人類用點選/畫重點的方式回饋，取代閱讀一大段文字/Markdown 的規劃書
- 規劃到位後，實作階段基本不需要人類介入

### 自動化審查流程（"No Mistakes" 概念）
- Agent 說做完了，**不要自己去看 diff 或手動測試**——那會變成瓶頸，因為人類每天能審的 diff 數量有限
- 交給一個獨立 pipeline：建立 branch → commit → 在隔離的 worktree 中執行 → rebase 到最新 main 並預先解衝突 → 用全新的 context window 做對抗性審查（adversarial review）→ 端對端測試並留存證據 → 更新相關文件 → lint 過關才 push → 開 PR → 持續監控 PR 直到合併
- 人類只需要看風險評估 + 證據，決定要花多少時間細看：低風險變更完全不看 diff，只有高風險變更才值得投入時間

### 長時間自主運行的 agent
- 給一個目標 + 停止條件，讓 agent 整晚自主迭代（例如「找出 app 中會困惑使用者的可用性問題並修掉，重複這個流程」）
- 適合「可驗證的目標」（降低 load time、提高測試覆蓋率）或「你信任 agent 判斷力」的目標

### 平行多個 agent（worktree 管理）
- 多個 agent 在同一目錄工作會互相干擾，要用 git worktree 隔離
- 手動管理 worktree（命名、記住哪個在用、事後刪除）本身會變成一種「債務」，需要工具自動化建立/重複利用/釋放 worktree

### 協調層（"船長的大副"）
- 當平行 agent 數量增加，人類在多個 session 間切換會非常疲累
- 解法是加一層協調 agent：你只跟這個「大副」說話，它負責拆解任務、平行分派給多個 worker agent（各自建 worktree、跑審查 pipeline 驗證），你只需要審核最終結果
- 用了協調層之後，瓶頸會從「執行力」轉移到「你能想清楚多少值得做的工作」——這代表你要花更多時間跟使用者聊、了解競爭態勢、規劃 roadmap，而不是盯著 agent 的輸出

---

## 如何從 0 開始把一個現有 repo 變 Claude-friendly

1. **建立專案級 memory file**：repo 根目錄放一份 `CLAUDE.md`（或 `AGENTS.md`，並互相 symlink），內容至少包含：
   - 這個專案是做什麼的、目錄佈局
   - 專案特有術語
   - 最重要的幾個元件如何運作
   - 如何跑端對端測試（比單元測試更能覆蓋真實產品行為，AI 預設容易只寫單元測試）
   - 團隊慣例（commit 訊息風格、分支策略等）
   - **不要一開始就寫齊全**：從一個精簡版本開始，之後每次 agent 犯錯就補一條規則進去
2. **建立/沿用全域 memory file**：把不隨專案而變的個人偏好（例如「不要用 em dash」「技術決策不要低估 AI 的開發速度、不要因此選廉價方案」「bug fix 前要先在最貼近使用者體驗的環境重現問題」）放進 `~/.claude/CLAUDE.md`，保持精簡，因為它會塞進每個 session 的 system prompt
3. **Symlink 讓多個 agent 共用同一份文件**（見本檔案開頭指令），避免 Claude Code / Cursor / Codex 各自維護一份不同步的說明
4. **memory file 變大時做瘦身**：把「只在特定情境需要」的內容（例如詳細的 e2e 測試步驟）抽成 project-level skill，善用 progressive disclosure 省 token。可以直接讓 agent 用 Anthropic 的 `skill-creator` skill 幫你抽
5. **盤點會給 agent 用的外部工具**：優先用 CLI 而非對應的 MCP server（實測 token 成本可差 3 倍、延遲差 2 倍以上），或設計/採用對 agent 友善的 wrapper
6. **只安裝有嚴謹 benchmark 佐證的 skill**，不要因為 GitHub star 高就裝，先自己測過再說
7. **建立一套審查 pipeline**（哪怕陽春版）：對抗性審查（用全新 context window 挑錯）+ 端對端測試留證據 + lint，讓「做完」的定義包含驗證，而不是丟給人類手動看 diff
8. **重複性高、可驗證的維護任務**，評估是否適合包成「長時間運行 + 明確停止條件」的自主任務，而不是每次都同步盯著

## 日後如何持續 improve harness

- **建立糾錯回饋迴圈**：每次發現 agent 做錯事，當下糾正，並把這次學習存進對應的 memory file/skill，讓下一個 session 不會重蹈覆轍——這是 harness 變聰明最主要的方式，不需要複雜的記憶系統
- **定期幫 memory file 瘦身**：把條件式資訊移到 skill，只留「幾乎每個 session 都用得到」的內容在 memory file 裡，控制 system prompt 的 token 開銷
- **持續 benchmark 你的工具鏈**：新增或替換工具（GitHub 存取方式、瀏覽器工具等）前，先量測 token 用量、成功率、延遲，汰換沒效率的選項
- **對「熱門」保持懷疑**：安裝任何聲稱能讓 agent 變強的 skill/repo 前，找有沒有嚴謹的評測數據，而不是只看 star 數
- **把審查自動化的比例逐步拉高**：目標是讓「diff review」不再是你每天的瓶頸，才有辦法真正靠增加 agent 數量來擴大產出
- **當單一 agent 的工作已經被排滿**，考慮引入協調層（一個統一入口 agent，負責拆解任務、管理 worktree、分派 worker），把自己從「跟每個 agent 逐一對話」解放出來
- **持續往上移動自己的角色**：隨著 agent 能處理的工作範圍擴大，把更多時間花在想清楚「該做什麼」（跟使用者對話、看競品、規劃方向），而不是「怎麼做」
