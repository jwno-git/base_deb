# Bash Config

# Prompt
if [[ -n "$DISPLAY" || "$XDG_SESSION_TYPE" == "wayland" ]]; then
	# In GUI Terminal
	if [[ $EUID -eq 0 ]]; then
    		# Root prompt: red
    		PS1=' \[\033[90m\]\w \[\033[91m\]root \[\033[36m\]>\[\033[0m\] '
	else
    		# User prompt: cyan
    		PS1=' \[\033[90m\]\w \[\033[36m\]>\[\033[0m\] '
	fi
else
	# In TTY Terminal
	if [[ $EUID -eq 0 ]]; then
    		# Root prompt: red
    		PS1=' \[\033[37m\]\w \[\033[91m\]root \[\033[36m\]>\[\033[0m\] '
	else
    		# User prompt: cyan
    		PS1=' \[\033[37m\]\w \[\033[36m\]>\[\033[0m\] '
	fi
fi

# Path configuration
export PATH="$HOME/.local/bin:$PATH"

# Environment variables
export EDITOR="vim"
export VISUAL="vim"
export XCURSOR_THEME="BreezeX-RosePine-Linux"
export XCURSOR_SIZE=24
# GTK Theme Configuration
export GTK_THEME="Tokyonight-Dark"
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export QT_STYLE_OVERRIDE=adwaita-dark  # Makes Qt apps look more consistent

# Common aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias engage='qtile start -b wayland'

# User-specific functions (only for regular user, not root)
if [[ $EUID -ne 0 ]]; then
    # Configuration management
    update_bash() {
        echo "Updating both user and root .bashrc files..."
        sudo cp ~/.bashrc /root/.bashrc
        echo "✓ Both configs updated"
        echo "Note: Changes will take effect on next shell session or after 'source ~/.bashrc'"
    }

    # Shell Commands
    # Services Monitor
    service_status() {
        echo "=== FAILED SERVICES (Critical!) ==="
        systemctl list-units --type=service --state=failed --no-pager
        echo -e "\n=== RUNNING SERVICES ==="
        systemctl list-units --type=service --state=running --no-pager
        echo -e "\n=== EXITED SERVICES (One-shot completed) ==="
        systemctl list-units --type=service --state=exited --no-pager
        echo -e "\n=== INACTIVE SERVICES ==="
        systemctl list-units --type=service --state=inactive --no-pager
        echo "... (showing first 10 inactive services)"
    }
    ser_status() {
    	service_status | less
    }
fi

# History configuration
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r"

# Display configuration and conditional fastfetch
fbset -g 2880 1800 2880 1800 32 2>/dev/null
clear

# Only run fastfetch in GUI environments (not TTY)
if [[ -n "$DISPLAY" || "$XDG_SESSION_TYPE" == "wayland" ]]; then
    fastfetch --logo none
fi

# BLE Completion/Command Verification
# Only load in interactive shells
if [[ $- == *i* ]]; then
    [[ -f /usr/local/share/blesh/ble.sh ]] && source /usr/local/share/blesh/ble.sh
fi

# BLE color configuration
if [[ ${BLE_VERSION-} ]]; then
    ble-color-setface command_function "fg=green"
    ble-color-setface command_builtin "fg=green"
    ble-color-setface command_alias "fg=green"
    ble-color-setface command_file "fg=green"
    ble-color-setface syntax_error "fg=red"
fi
