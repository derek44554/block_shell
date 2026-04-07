#!/usr/bin/env bash
# upgrade_node.sh
# 节点升级：停止当前容器，拉取最新代码，重新构建并启动服务。
set -e
source "$(dirname "$0")/common.sh"

echo "==> 升级节点..."
docker-compose -f "$REPO_DIR/docker-compose.yml" down
git -C "$REPO_DIR" pull
docker-compose -f "$REPO_DIR/docker-compose.yml" up -d --build

echo ""
echo "✅ 节点升级完成！"
echo "   本地访问: http://localhost:24001"
