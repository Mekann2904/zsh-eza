## === eza スマート設定（高速化版） ===
# 既存エイリアス解除
for a in t tg g gg l ll la ee; do unalias "$a" 2>/dev/null; done

# eza がなければ素直に ls にフォールバックして終了
if ! command -v eza >/dev/null 2>&1; then
  alias ls='ls -G'
  alias ll='ls -l'
  alias la='ls -la'
  ee() { command ls "$@"; }
  t()  { ee "$@"; }
  tg() { ee "$@"; }
  g()  { ee "$@"; }
  gg() { ee "$@"; }
  l()  { ee -1 "$@"; }
  ll() { ee -l "$@"; }
  la() { ee -la "$@"; }
else
  # --- 高速化のためオプションをハードコード (eza --help を毎回実行しない) ---
  
  # 基本オプション (アイコン有効化など)
  typeset -a EZA_BASE_OPTS
  EZA_BASE_OPTS=(--group-directories-first --icons)

  # Tree表示用オプション (Git連携、ヘッダー、時刻形式など)
  typeset -a EZA_TREE_OPTS
  EZA_TREE_OPTS=(-T -L 2 -l -h --git --header --time-style=long-iso)
  
  # Grid表示用オプション
  typeset -a EZA_GRID_OPTS
  EZA_GRID_OPTS=()

  # 無視するファイルパターン
  : ${EZA_IGNORE_GLOB:="node_modules|.git|dist|build|.next|target|venv|.venv"}
  
  # 出力行数の閾値
  : ${EZA_MAX_LINES:=80}

  # 常にカラー表示
  typeset -a EZA_COLOR_ALWAYS
  EZA_COLOR_ALWAYS=(--color=always)
  
  # ベース関数
  ee() { command eza "${EZA_BASE_OPTS[@]}" "$@"; }

  # --- 自動 ls の ON/OFF と起動直後スキップ用フラグ ---
  : ${EZA_AUTO:=1}     # 0 にすると chpwd 自動 ls を無効化
  EZA_SKIP_ONCE=1      # 起動直後の load_last_dir 由来 chpwd を 1 回だけスキップ

  # 行数で tree/grid を切り替えるスマート ls
  _eza_smart() {
    # 非対話なら何もしない
    [[ -t 1 ]] || return 0

    # 自動 ls 無効
    [[ "$EZA_AUTO" = 1 ]] || return 0

    # 起動直後 1 回だけはスキップ（load_last_dir の chpwd 対策）
    if [[ -n "$EZA_SKIP_ONCE" ]]; then
      unset EZA_SKIP_ONCE
      return 0
    fi

    # mktemp のテンプレートを明示し、失敗時は終了
    local tmp
    tmp=$(command mktemp -t eza_out.XXXXXX) || return 1

    # tree 表示を一度だけ生成してファイルに保存
    # (オプションはハードコード済みなので条件分岐削除)
    ee "${EZA_COLOR_ALWAYS[@]}" "${EZA_TREE_OPTS[@]}" --ignore-glob "$EZA_IGNORE_GLOB" >! "$tmp" 2>/dev/null

    # 行数を見て tree / grid を切り替え
    local lines
    lines=$(wc -l <"$tmp" | tr -d ' ')

    if (( ${lines:-0} <= EZA_MAX_LINES )); then
      # 少ないときは tree 出力をそのまま表示
      cat "$tmp"
    else
      # 多いときは grid で一覧（ここは eza をもう一度実行）
      ee "${EZA_COLOR_ALWAYS[@]}" "${EZA_GRID_OPTS[@]}" --ignore-glob "$EZA_IGNORE_GLOB"
    fi

    rm -f "$tmp"
  }

  # ディレクトリ移動時に自動で _eza_smart を実行
  chpwd() { _eza_smart }

  # --- エイリアス/関数定義 ---

  t() {
    ee "${EZA_TREE_OPTS[@]}" --ignore-glob "$EZA_IGNORE_GLOB" "$@"
  }

  tg() {
    # 深めのTree探索用
    local opts=(-T -L 3 -l -h --git --header --time-style=long-iso)
    ee "${opts[@]}" --ignore-glob "$EZA_IGNORE_GLOB" "$@"
  }

  g() { 
    ee "${EZA_GRID_OPTS[@]}" "$@"
  }

  gg() {
    ee --git "$@"
  }

  l() { 
    ee -1 "$@"
  }

  ll() {
    local opts=(-l -h --header --git --time-style=long-iso)
    ee "${opts[@]}" "$@"
  }

  la() {
    local opts=(-la -h --header --git --time-style=long-iso)
    ee "${opts[@]}" "$@"
  }
  
  # ls をオーバーライド
  ls() {
    if [[ $# -eq 0 ]]; then
      _eza_smart
    else
      command eza "$@"
    fi
  }
fi


