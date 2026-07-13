# Treehouse 新手教學

## 什麼是 Treehouse？

[Treehouse](https://github.com/kunchenguid/treehouse) 是一個管理 git worktree 「重複使用池（pool）」的 CLI 工具。

一句話說明它在做什麼：**"Manage worktrees without managing worktrees."** —— 你不用自己去想 worktree 要取什麼名字、放在哪裡、做完要不要刪，Treehouse 幫你全部處理掉。

---

## 為什麼需要它？（agentic workflow 的痛點）

### 問題：多個 agent 同時工作會互相干擾

如果你同時開好幾個 Claude Code / Codex session 在**同一個 repo 目錄**下工作，它們會共用同一份 working directory：一個 agent 改的檔案、切的 branch，會直接影響另一個正在跑的 agent，很容易互相打架、產生衝突。

### 常見解法：`git worktree`，但它自己會變成負擔

`git worktree add ../repo-2` 可以建立一個獨立目錄，讓不同 agent 互不干擾。但純手動管理 worktree 會遇到三個麻煩：

1. **命名要花腦力**：每次都要想一個新目錄名字（`repo-2`、`repo-hotfix`……很快就亂掉）
2. **要自己記帳**：哪個 worktree 還在用、哪個已經沒人用了，全部要靠腦袋記
3. **用完要手動清**：不清掉的話，硬碟會堆一堆用過即丟的 worktree，變成技術債

### Treehouse 的解法

Treehouse 維護一個 worktree **池**：

- 需要一個乾淨環境時，跟它要一個（`treehouse get`）——它會**重複利用**一個目前閒置的 worktree（保留上次裝好的 dependencies、build cache），沒有閒置的才會新建一個
- 你在裡面工作、跑 agent、改 code
- 做完之後，**離開這個 worktree 就自動歸還給池子**，供下一次重複使用，不需要手動刪除

好處：每個平行工作的 agent 都有自己完全隔離的目錄，不會撞在一起，而你完全不需要記名字、記狀態、記得清理。

---

## 安裝

```sh
# macOS / Linux
curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh

# Windows（PowerShell）
irm https://kunchenguid.github.io/treehouse/install.ps1 | iex

# 或用 Go 安裝
go install github.com/kunchenguid/treehouse@latest

# 確認安裝成功
treehouse --version
```

---

## 基本用法

### 1. 拿一個 worktree 來用

```sh
cd 你的repo目錄
treehouse
# 等同於：
treehouse get
```

執行後會把你丟進一個全新（或重複利用）的 worktree 子 shell，裡面是 detached HEAD，對齊你 repo 目前最新的 default branch。你可以直接在這裡叫 agent 開始工作。

工作做完後，直接 `exit` 離開這個子 shell，Treehouse 就知道你用完了，會把這個 worktree 放回池子，等下次重複使用。

### 2. 查看目前池子狀態

```sh
treehouse status
```

會列出目前有哪些 worktree、哪些正在使用中、哪些是閒置可重複利用的。

### 3. 平行開多個 agent

在 tmux 裡開好幾個分頁，每個分頁各自 `cd` 進同一個 repo，各自跑一次 `treehouse`，就會拿到互不干擾的獨立環境：

```sh
# 分頁 1
treehouse   # 進入 worktree A，跑 agent 處理 feature X

# 分頁 2
treehouse   # 進入 worktree B，跑 agent 處理 feature Y

# 分頁 3
treehouse   # 進入 worktree C，跑 agent 處理 bugfix Z
```

三個 agent 全部平行運作，各自的檔案改動完全不會互相污染。

### 4. 非互動場景：讓 agent 自己拿 worktree（lease）

如果你想在腳本或協調 agent（例如一個負責拆解任務、分派給多個 worker 的上層 agent）裡取得 worktree 路徑而不進子 shell，可以用 `--lease`：

```sh
path=$(treehouse get --lease)
cd "$path"
# ...工作完成後手動歸還
treehouse return "$path"
```

`--lease` 是「持久保留」，不依賴一個持續存在的子 shell 進程，適合自動化流程。

### 5. 清理

```sh
treehouse prune          # 先看看有哪些過期 worktree 可以清（dry-run）
treehouse prune --yes    # 真的執行清理
treehouse destroy <path> # 指定刪除某個 worktree
```

---

## 設定（可選）

repo 層級設定放在 repo 根目錄的 `treehouse.toml`，全域設定放 `~/.config/treehouse/config.toml`：

```toml
max_trees = 16
root = "$HOME/worktrees"
```

還可以設定 `post_create`（worktree 建立後執行，例如自動裝 dependencies）跟 `pre_destroy`（刪除前執行）hook，讓每個新 worktree 開箱即用。

---

## 如何加速 agentic workflow

把 Treehouse 放進你的 agent 工作流後，具體帶來的效率提升：

1. **平行度不再受限於「記名字的心力」**：以前每多開一個 agent，就要多花幾分鐘想目錄名稱、記錄狀態；現在一個指令 `treehouse` 就搞定，平行開 3、5 個 agent 跟開 1 個一樣輕鬆
2. **省掉重複安裝 dependencies 的時間**：worktree 歸還池子後，dependencies 跟 build cache 會被保留，下次重複利用時不用重新 `npm install` / 重新 build，agent 可以立刻開始改 code
3. **腦袋不用當 worktree 的資料庫**：你不用記「哪個目錄還有 agent 在跑、哪個已經沒用了」，`treehouse status` 隨時可以查，減少心智負擔，才有餘裕真正管理多個平行任務
4. **跟長時間自主運行的 agent 搭配更好**：例如睡前丟一個長跑任務進某個 worktree，隔天早上 `treehouse status` 就能看到它還在跑還是已經還回池子了
5. **是搭建「多 agent 協調層」的基礎建設**：如果你想做一個統一入口的上層 agent，幫你自動拆解任務、平行分派給多個 worker agent，Treehouse 的 `--lease` 模式正是讓上層 agent 能夠**用程式化方式**（而不是人工開分頁）取得隔離環境的關鍵一塊
