# Fish shell configuration
# This file is loaded for interactive fish sessions

# Auto-start or attach to tmux
# This ensures you're always in a tmux session when using the terminal
if status is-interactive
    # Only run if we're not already in a tmux session
    and not set -q TMUX
    # And if tmux is available
    and command -v tmux >/dev/null

    # Try to attach to existing session named "main"
    # If it doesn't exist, create it
    if tmux has-session -t main 2>/dev/null
        exec tmux attach-session -t main
    else
        exec tmux new-session -s main
    end
end

# Useful aliases
alias ll='eza -l --icons'
alias la='eza -la --icons'
alias lt='eza --tree --icons'
alias cat='bat'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
alias lg='lazygit'

# Helpful functions
function mkcd
    mkdir -p $argv[1]
    and cd $argv[1]
end

# Welcome message
if status is-interactive
    echo "Welcome back, Edgar!"
    echo "Type 'exit' twice to leave tmux and fish"
end
