# Tmux 新手教學

## 什麼是 Tmux？

Tmux 是一個「終端機多工器」（Terminal Multiplexer）。
簡單來說，它讓你在一個終端機視窗裡同時管理多個工作階段（session）、視窗（window）、和窗格（pane）。

---

## 為什麼要用 Tmux？尤其是搭配 Claude Code

### 問題：沒有 Tmux 的痛苦

當你使用 Claude Code 開發時，你通常需要同時做很多事：

- 讓 Claude Code 在背景執行長時間任務（build、test、agent loop）
- 自己也需要在終端機查看檔案或執行指令
- 有時候還需要開著 dev server、跑 logs

沒有 Tmux 的話，你要開很多個終端機視窗，切換困難，而且一旦關掉視窗，正在執行的工作就中斷了。

### 解決方案：Tmux 的三大優勢

**1. 工作不會因為關掉視窗而中斷**
Tmux 的 session 跑在背景伺服器裡。
就算你關掉 terminal app、SSH 連線斷線，工作仍然繼續執行。
之後用 `tmux attach` 重新連回去，一切都還在。

**2. 一個畫面分割成多個窗格，同時看到所有資訊**
你可以把畫面分成左右兩半：左邊跑 Claude Code，右邊看 logs 或執行自己的指令。
再也不用一直切換視窗。

**3. 搭配 Claude Code 的 `--dangerously-skip-permissions` 模式**
當 Claude Code 在自動化模式下執行時，你需要一個方式在背景讓它持續運作，同時自己還能做其他事。
Tmux 就是標準解法 - Claude Code 官方文件也推薦這個做法。

---

## 核心概念

理解這三個層級，之後的指令就一目了然：

```
Session（工作階段）
  └── Window（視窗，像瀏覽器的分頁）
        └── Pane（窗格，一個 window 裡的分割畫面）
```

- **Session**：一個獨立的工作環境，可以取名字（例如 `coding`、`devserver`）
- **Window**：session 裡的分頁，可以有多個，每個有自己的名稱
- **Pane**：一個 window 裡再分割出來的區塊

---

## 安裝

```sh
# macOS（使用 Homebrew）
brew install tmux

# 確認安裝成功
tmux -V
```

---

## 基本操作指南

### Prefix 鍵

Tmux 的所有快捷鍵都需要先按 **Prefix**，預設是 `Ctrl + b`。
按下 Prefix 後放開，再按下一個鍵。

> 例如：`Ctrl+b` 然後 `c` = 新增一個 window

---

### Session 管理

| 指令 | 說明 |
|------|------|
| `tmux` | 開啟新的 session |
| `tmux new -s 名稱` | 開啟並命名 session |
| `tmux ls` | 列出所有 session |
| `tmux attach -t 名稱` | 重新連接到 session |
| `tmux kill-session -t 名稱` | 刪除 session |
| `Prefix + d` | **Detach**（離開但不關閉 session） |
| `Prefix + $` | 重新命名目前 session |
| `Prefix + s` | 列出並切換 session |

---

### Window（分頁）管理

| 指令 | 說明 |
|------|------|
| `Prefix + c` | 新增 window |
| `Prefix + ,` | 重新命名目前 window |
| `Prefix + n` | 切換到下一個 window |
| `Prefix + p` | 切換到上一個 window |
| `Prefix + 數字` | 直接跳到第 N 個 window（0-9） |
| `Prefix + w` | 列出所有 window 並選擇 |
| `Prefix + &` | 關閉目前 window |

---

### Pane（窗格）管理

| 指令 | 說明 |
|------|------|
| `Prefix + %` | 左右分割 |
| `Prefix + "` | 上下分割 |
| `Prefix + 方向鍵` | 切換到相鄰的 pane |
| `Prefix + z` | 放大/縮小目前 pane（zoom toggle） |
| `Prefix + x` | 關閉目前 pane |
| `Prefix + {` | 把目前 pane 向左移 |
| `Prefix + }` | 把目前 pane 向右移 |
| `Prefix + Space` | 循環切換 pane 排列方式 |

調整 pane 大小：按住 `Prefix` 不放，再按方向鍵。

---

### 複製模式（Copy Mode）

在 tmux 裡滾動畫面需要進入 Copy Mode：

| 指令 | 說明 |
|------|------|
| `Prefix + [` | 進入 Copy Mode |
| 方向鍵 / Page Up/Down | 滾動畫面 |
| `q` | 離開 Copy Mode |

---

## 搭配 Claude Code 的實際工作流

### 場景一：讓 Claude Code 在背景執行，自己也能用終端機

```sh
# 1. 建立一個命名 session
tmux new -s claude

# 2. 分割畫面：左邊給 Claude Code，右邊自己用
# 按 Prefix + %

# 3. 左邊啟動 Claude Code
claude

# 4. 切到右邊的 pane（Prefix + 方向鍵右）
# 在右邊做你自己的事

# 5. 需要離開電腦時，detach session
# 按 Prefix + d

# 6. 下次回來重新連接
tmux attach -t claude
```

### 場景二：多個專案並行

```sh
# 專案 A
tmux new -s projectA
# 做 projectA 的事
# Prefix + d 離開

# 專案 B
tmux new -s projectB
# 做 projectB 的事
# Prefix + d 離開

# 列出所有 session
tmux ls
# projectA: 1 windows (created ...)
# projectB: 1 windows (created ...)

# 切回 projectA
tmux attach -t projectA
```

### 場景三：Claude Code + Dev Server + Logs 同時監控

```sh
# 新建 session
tmux new -s dev

# 先把畫面分成上下兩半（Prefix + "）
# 上半：Prefix + %再左右分成兩塊

# 最終佈局：
# ┌─────────────┬─────────────┐
# │  Claude     │  Dev Server │
# │  Code       │  (npm run   │
# │             │   dev)      │
# ├─────────────┴─────────────┤
# │  Logs / git status        │
# └───────────────────────────┘
```

---

## 推薦的基本設定（~/.tmux.conf）

建立這個設定檔可以讓 tmux 更好用：

```sh
# 把 Prefix 改成 Ctrl+a（很多人覺得比 Ctrl+b 好按）
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 讓 pane 編號從 1 開始（比較直覺）
set -g base-index 1
setw -g pane-base-index 1

# 用 vim 風格在 pane 間移動
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# 開啟滑鼠支援（可以用滑鼠點選 pane、調整大小）
set -g mouse on

# 增加 scrollback 歷史記錄
set -g history-limit 10000

# 讓顏色正常顯示
set -g default-terminal "screen-256color"
```

套用設定：

```sh
# 重新載入設定（在 tmux 裡執行）
tmux source-file ~/.tmux.conf

# 或直接用 Prefix + :
# 輸入 source-file ~/.tmux.conf
```

---

## 常見問題

**Q：按了 Prefix 沒反應？**
確認你先按 `Ctrl+b`（按下後放開），再按下一個鍵，不是同時按。

**Q：SSH 斷線後工作還在嗎？**
在。只要你是在 tmux session 裡執行，SSH 斷線不影響。重新 SSH 連線後 `tmux attach` 即可。

**Q：Tmux 關掉後資料還在嗎？**
`Prefix + d`（detach）離開的 session 資料都還在。
只有 `tmux kill-session` 或系統重開機才會消失。

**Q：我的設定改了但沒生效？**
執行 `tmux source-file ~/.tmux.conf` 重新載入，或重開一個新的 session。

---

## 快速備忘卡

```
最常用的指令
─────────────────────────────────────
tmux new -s <名稱>     開新 session
tmux attach -t <名稱>  重連 session
tmux ls               列出所有 session

Prefix = Ctrl+b（預設）
─────────────────────────────────────
Prefix + d    離開（session 繼續跑）
Prefix + c    新 window
Prefix + %    左右分割 pane
Prefix + "    上下分割 pane
Prefix + 方向鍵  切換 pane
Prefix + z    放大/縮小 pane
Prefix + s    切換 session
Prefix + [    進入 scroll 模式
```

---

## 下一步

掌握以上基礎後，可以進一步研究：

- [tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/tpm) - 用插件擴充功能
- `tmux-resurrect` - 重開機後自動還原 session
- `tmux-continuum` - 自動儲存 session 狀態
- Neovim + tmux 整合（用 `vim-tmux-navigator` 無縫切換）
