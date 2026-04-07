#!/usr/bin/env bash
# common.sh
# 公共变量与工具函数，供其他脚本通过 source 引用。
# 包含：路径变量、IPFS 询问与启动、App 密钥生成、部署结果输出。

KEY_DIR="${HOME:-/root}/block_key"
REPO_DIR="${HOME:-/root}/BlockBase"

check_deps() {
    local pkgs=()
    command -v git    &>/dev/null || pkgs+=(git)
    command -v docker &>/dev/null || pkgs+=(docker.io)
    if [ ${#pkgs[@]} -gt 0 ]; then
        echo "==> 安装缺失依赖: ${pkgs[*]}"
        if command -v apt-get &>/dev/null; then
            apt-get update -q && apt-get install -y "${pkgs[@]}"
        elif command -v yum &>/dev/null; then
            yum install -y "${pkgs[@]}"
        elif command -v dnf &>/dev/null; then
            dnf install -y "${pkgs[@]}"
        else
            echo "错误：无法自动安装依赖，请手动安装: ${pkgs[*]}"
            exit 1
        fi
    fi
    # 安装后刷新 PATH
    hash -r 2>/dev/null || true
    export PATH="/usr/bin:/usr/sbin:/usr/local/bin:$PATH"
    # docker-compose 兼容：优先用插件，否则安装独立版
    if ! command -v docker-compose &>/dev/null; then
        if docker compose version &>/dev/null 2>&1; then
            # docker compose 插件可用，创建别名
            echo '#!/bin/sh' > /usr/local/bin/docker-compose
            echo 'exec docker compose "$@"' >> /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose
        else
            echo "==> 安装 docker-compose..."
            if command -v apt-get &>/dev/null; then
                apt-get install -y docker-compose
            fi
        fi
    fi
}

ask_ipfs() {
    read -r -p "是否开启 IPFS 存储？[y/N] " ENABLE_IPFS
    ENABLE_IPFS=$(echo "$ENABLE_IPFS" | tr '[:upper:]' '[:lower:]')
    export ENABLE_IPFS
}

setup_ipfs() {
    # 刷新 PATH，确保刚安装的 docker 可以找到
    hash -r 2>/dev/null || true
    export PATH="/usr/bin:/usr/sbin:/usr/local/bin:$PATH"

    echo "==> 创建 Docker 网络 block（已存在则忽略）..."
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
                -v /home/IPFS:/data/ipfs \
                -p 4001:4001 \
                -p 8080:8080 \
                -p 127.0.0.1:5001:5001 \
                -e IPFS_PATH=/data/ipfs \
                ipfs/go-ipfs:latest \
                daemon --migrate=true --agent-version-suffix=docker
        fi

        if ! grep -q "ipfs_api" "$REPO_DIR/node.yml" 2>/dev/null; then
            echo "ipfs_api: http://ipfs:5001/api/v0" >> "$REPO_DIR/node.yml"
            echo "    已写入 ipfs_api 到 node.yml"
        fi
    else
        echo "==> 已跳过 IPFS 容器"
    fi
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
    echo "   App 端密钥:  $(grep IDENTITY "$REPO_DIR/.env" | cut -d= -f2)"
    if [ "$ENABLE_IPFS" = "y" ]; then
        echo "   IPFS 地址:   http://localhost:8080/ipfs/"
    fi
}
