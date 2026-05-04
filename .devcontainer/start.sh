#!/bin/bash
# IGSIGN startup script — auto-runs on Codespace wake
set -e

echo '=== IGSIGN Auto-Start ==='

# 1. Start PostgreSQL
echo '>> Starting PostgreSQL...'
sudo service postgresql start 2>&1 | tail -1 || true
sleep 1

# 2. Kill stale processes from previous session
pkill -f 'rails s' 2>/dev/null || true
pkill -f 'puma' 2>/dev/null || true
pkill -f 'cloudflared' 2>/dev/null || true
tmux kill-server 2>/dev/null || true
sleep 1

# 3. Start Rails + Cloudflare tunnel in tmux
echo '>> Starting Rails...'
cd /workspaces/docuseal
tmux new-session -d -s igsign -n rails
tmux send-keys -t igsign:rails 'cd /workspaces/docuseal && bundle exec rails s -b 0.0.0.0 -p 3000 2>&1 | tee /tmp/rails.log' Enter

# 4. Wait for Rails to be ready then start tunnel
tmux new-window -t igsign -n tunnel
tmux send-keys -t igsign:tunnel 'sleep 20 && /tmp/cloudflared tunnel --url http://localhost:3000 --no-autoupdate 2>&1 | tee /tmp/tunnel.log' Enter

echo '=== IGSIGN starting — run: grep trycloudflare /tmp/tunnel.log to get your public URL ==='
