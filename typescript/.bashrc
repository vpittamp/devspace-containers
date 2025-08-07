# Bash history configuration for TypeScript devcontainer
# This ensures command history persists across container sessions

# History size configuration
export HISTSIZE=10000
export HISTFILESIZE=20000

# Store history in /app directory (which is the mounted volume)
export HISTFILE=/app/.bash_history

# History control options
# ignoreboth = ignorespace + ignoredups (ignore commands starting with space and duplicates)
# erasedups = remove older duplicate entries
export HISTCONTROL=ignoreboth:erasedups

# Add timestamp to history entries
export HISTTIMEFORMAT="%F %T "

# Append to history file instead of overwriting
shopt -s histappend

# Save multi-line commands as one command
shopt -s cmdhist

# Update history file after each command
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"