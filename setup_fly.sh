#!/usr/bin/env bash
set -e
APP_NAME="igsign-ig"
APP_DIR="/workspaces/docuseal"
echo "=== IGSIGN Fly.io Setup ==="
if ! command -v flyctl &>/dev/null; then
  curl -L https://fly.io/install.sh | sh
  export PATH="$HOME/.fly/bin:$PATH"
  echo 'export PATH="$HOME/.fly/bin:$PATH"' >> ~/.bashrc
fi
if ! flyctl auth whoami &>/dev/null; then
  flyctl auth login
fi
cd "$APP_DIR"
flyctl apps create "$APP_NAME" --machines 2>/dev/null || echo "App exists, continuing..."
DB_APP="${APP_NAME}-db"
flyctl postgres create --name "$DB_APP" --region jnb --initial-cluster-size 1 --vm-size shared-cpu-1x --volume-size 1 2>/dev/null || echo "DB exists, continuing..."
flyctl postgres attach "$DB_APP" --app "$APP_NAME" 2>/dev/null || true
SKB=$(bundle exec rails secret 2>/dev/null || openssl rand -hex 64)
flyctl secrets set SECRET_KEY_BASE="$SKB" --app "$APP_NAME" 2>/dev/null || true
flyctl deploy --app "$APP_NAME" --remote-only
echo ""; echo "Deployed: https://${APP_NAME}.fly.dev"
