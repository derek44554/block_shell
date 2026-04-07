#!/usr/bin/env bash
set -e

REPO_URL="https://raw.githubusercontent.com/derek44554/block_shell/main"
SCRIPT_DIR="$(dirname "$0")/scripts"

# 如果 scripts/ 目录不存在，说明是远程执行，自动下载所有子脚本
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "==> 下载脚本文件..."
    TMP_DIR=$(mktemp -d)
    mkdir -p "$TMP_DIR/scripts"
    for f in common.sh fresh_deploy.sh add_node.sh start_node.sh upgrade_node.sh enable_ipfs.sh; do
        curl -fsSL "$REPO_URL/scripts/$f" -o "$TMP_DIR/scripts/$f"
        chmod +x "$TMP_DIR/scripts/$f"
    done
    SCRIPT_DIR="$TMP_DIR/scripts"
fi

echo "请选择操作："
echo "  1) 全新部署"
echo "  2) 新增节点（已有顶级密钥）"
echo "  3) 启动已有节点"
echo "  4) 节点升级"
echo "  5) 开启 IPFS 存储"
read -r -p "请输入选项 [1-5]: " MENU

case "$MENU" in
    1) bash "$SCRIPT_DIR/fresh_deploy.sh" ;;
    2) bash "$SCRIPT_DIR/add_node.sh" ;;
    3) bash "$SCRIPT_DIR/start_node.sh" ;;
    4) bash "$SCRIPT_DIR/upgrade_node.sh" ;;
    5) bash "$SCRIPT_DIR/enable_ipfs.sh" ;;
    *)
        echo "无效选项，退出。"
        exit 1
        ;;
esac
