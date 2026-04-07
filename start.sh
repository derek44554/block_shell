#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(dirname "$0")/scripts"

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
