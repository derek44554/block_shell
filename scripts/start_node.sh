#!/usr/bin/env bash
# start_node.sh
# 启动已有节点：直接启动已部署的 Docker 容器，不做任何密钥或配置操作。
set -e
source "$SCRIPT_DIR/common.sh"

echo "==> 启动已有节点..."
docker-compose -f "$REPO_DIR/docker-compose.yml" up -d

echo ""
echo "✅ 节点已启动！"
echo "   本地访问: http://localhost:24001"
