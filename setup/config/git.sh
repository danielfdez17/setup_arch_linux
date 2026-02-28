#!/bin/bash
set -e

# Git identity
git config --global user.name "danielfdez17"
git config --global user.email "daniel17dev@gmail.com"

# Git command aliases (usable as: git ga, git gc, ...)
git config --global alias.ga 'add'
git config --global alias.gc 'commit -m'
git config --global alias.gp 'push'
git config --global alias.gl 'log --oneline --graph --decorate'
git config --global alias.gss 'status -s'
git config --global alias.gpr 'pull --rebase'
git config --global alias.gls 'ls-files'
git config --global alias.gconf 'config --global --edit'

# Shell aliases (usable as: ga, gc, ...) persisted across sessions
ALIAS_FILE="$HOME/.b2b_git_aliases"
cat > "$ALIAS_FILE" << 'EOF'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gss='git status -s'
alias gpr='git pull --rebase'
alias gls='git ls-files'
alias gconf='git config --global --edit'
EOF

ensure_source_line() {
	local rc_file="$1"
	local marker="# Born2beRoot Git aliases"
	local source_line='[ -f "$HOME/.b2b_git_aliases" ] && . "$HOME/.b2b_git_aliases"'

	[ -f "$rc_file" ] || touch "$rc_file"
	if ! grep -Fq "$source_line" "$rc_file" 2>/dev/null; then
		{
			echo ""
			echo "$marker"
			echo "$source_line"
		} >> "$rc_file"
	fi
}

ensure_source_line "$HOME/.bashrc"
ensure_source_line "$HOME/.zshrc"

# Cloning useful Git repositories
# REPOS=(
#     "https://github.com/Univers42/transcendence",
#     "https://github.com/Univers42/mini-baas",
# )

# for repo in "${REPOS[@]}"; do
#     if [ ! -d "$HOME/$(basename "$repo" .git)" ]; then
#         git clone "$repo" "$HOME/$(basename "$repo" .git)"
#     fi
# done

echo "Git configuration and persistent aliases applied"