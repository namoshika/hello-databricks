#!/bin/sh

echo "Setting up Wiki.js..."

# Wiki.js v2.5.314 をダウンロード
wget -q https://github.com/Requarks/wiki/releases/download/v2.5.314/wiki-js.tar.gz

# 展開
tar xzf wiki-js.tar.gz
rm wiki-js.tar.gz

# 依存パッケージをインストール
npm install --only=production --legacy-peer-deps

echo "Wiki.js setup completed."

# config.yml を毎回生成（環境変数の値を反映するため）
cat > config.yml <<EOF
port: $DATABRICKS_APP_PORT
bindIP: 0.0.0.0

db:
    type: postgres
    host: $PGHOST
    port: 5432
    user: $DB_USER
    pass: $DB_PASS
    db: $DB_NAME
    ssl: true
    sslOptions:
    auto: true

logLevel: info
dataPath: /tmp/wiki-data
EOF

# Wiki.js を起動
exec node server
