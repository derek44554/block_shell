#!/usr/bin/env bash
# common.sh
# 公共变量与工具函数，供其他脚本通过 source 引用。
# 包含：路径变量、IPFS 询问与启动、App 密钥生成、部署结果输出。

KEY_DIR="${HOME:-/root}/block_key"
REPO_DIR="${HOME:-/root}/BlockBase"

check_deps() {
    # 安装 git
    if ! command -v git &>/dev/null; then
        echo "==> 安装 git..."
        if command -v apt-get &>/dev/null; then
            apt-get update -q && apt-get install -y git
        elif command -v yum &>/dev/null; then
            yum install -y git
        elif command -v dnf &>/dev/null; then
            dnf install -y git
        fi
    fi

    # 安装 docker（用官方脚本）
    if ! command -v docker &>/dev/null; then
        echo "==> 安装 Docker..."
        # 先移除可能冲突的旧版本
        apt-get remove -y docker.io docker-compose containerd runc 2>/dev/null || true
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker 2>/dev/null || true
    fi

    # 安装 docker-compose
    if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null 2>&1; then
        echo "==> 安装 docker-compose..."
        if command -v apt-get &>/dev/null; then
            apt-get install -y docker-compose-plugin 2>/dev/null || \
            apt-get install -y docker-compose 2>/dev/null || true
        fi
    fi
}

ask_ipfs() {
    read -r -p "是否开启 IPFS 存储？[Y/n] " ENABLE_IPFS
    ENABLE_IPFS=$(echo "${ENABLE_IPFS:-y}" | tr '[:upper:]' '[:lower:]')
    export ENABLE_IPFS
}

setup_ipfs_config() {
    if [ "$ENABLE_IPFS" = "y" ]; then
        if ! grep -q "ipfs_api" "$REPO_DIR/node.yml" 2>/dev/null; then
            echo "ipfs_api: http://ipfs:5001/api/v0" >> "$REPO_DIR/node.yml"
            echo "==> 已写入 ipfs_api 到 node.yml"
        fi
    fi
}

start_docker() {
    docker network create block 2>/dev/null || true

    if [ "$ENABLE_IPFS" = "y" ]; then
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
    fi

    docker compose -f "$REPO_DIR/docker-compose.yml" up -d 2>/dev/null || \
        docker-compose -f "$REPO_DIR/docker-compose.yml" up -d
}

generate_identity() {
    if [ ! -f "$REPO_DIR/.env" ] || ! grep -q "IDENTITY" "$REPO_DIR/.env"; then
        echo "==> 生成 App 配置密钥..."
        IDENTITY=$(python3 - <<PYEOF
import os, base64
print(base64.b64encode(os.urandom(32)).decode("utf-8"))
PYEOF
)
        echo "IDENTITY=$IDENTITY" >> "$REPO_DIR/.env"
        echo "    已写入 IDENTITY 到 .env"
    else
        echo "==> App 配置密钥已存在，跳过生成"
    fi
}

print_result() {
    echo ""
    echo "✅ 部署完成！"
    echo "   本地访问:    http://localhost:24001"
    echo "   App 端密钥:  $(grep IDENTITY "$REPO_DIR/.env" | sed 's/^IDENTITY=//')"
    echo "   节点目录:    $REPO_DIR"
    if [ "$ENABLE_IPFS" = "y" ]; then
        echo "   IPFS 地址:   http://localhost:8080/ipfs/"
        echo "   IPFS 数据:   $HOME/IPFS"
    fi
}
