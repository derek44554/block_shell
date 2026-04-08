#!/usr/bin/env bash
# enable_ipfs.sh
# 为已有节点开启 IPFS 存储：启动 IPFS 容器，并将 ipfs_api 写入指定节点的 node.yml。
set -e
source "$SCRIPT_DIR/common.sh"

# 步骤 1: 启动 IPFS 容器
echo "==> 创建 Docker 网络 block（已存在则忽略）..."
docker network create block 2>/dev/null || true

echo "==> 启动 IPFS 容器..."
if docker ps -a --format '{{.Names}}' | grep -q '^ipfs$'; then
    echo "    IPFS 容器已存在，跳过创建"
else
    docker run -d \
        --name ipfs \
        --restart always \
        --network block \
        -v "$HOME/IPFS:/data/ipfs" \
        -p 4001:4001 \
        -p 8080:8080 \
        -p 127.0.0.1:5001:5001 \
        -e IPFS_PATH=/data/ipfs \
        ipfs/go-ipfs:latest \
        daemon --migrate=true --agent-version-suffix=docker
fi

# 步骤 2: 选择节点目录
echo ""
echo "请选择节点目录："
echo "  1) 默认目录 ($REPO_DIR)"
read -r -p "  2) 手动输入路径  [1/2]: " DIR_CHOICE

if [ "$DIR_CHOICE" = "2" ]; then
    read -r -p "请输入节点目录路径: " NODE_DIR
    NODE_DIR="${NODE_DIR/#\~/$HOME}"
else
    NODE_DIR="$REPO_DIR"
fi

NODE_YML="$NODE_DIR/node.yml"

if [ ! -f "$NODE_YML" ]; then
    echo "错误：未找到 $NODE_YML，请确认节点目录是否正确。"
    exit 1
fi

# 步骤 3: 写入 ipfs_api
if grep -q "ipfs_api" "$NODE_YML"; then
    echo "==> ipfs_api 已存在于 node.yml，跳过写入"
else
    echo "ipfs_api: http://127.0.0.1:5001/api/v0" >> "$NODE_YML"
    echo "==> 已写入 ipfs_api 到 $NODE_YML"
fi

echo ""
echo "✅ IPFS 已开启！"
echo "   IPFS 地址: http://localhost:8080/ipfs/"
echo "   节点配置:  $NODE_YML"
