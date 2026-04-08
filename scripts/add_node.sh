#!/usr/bin/env bash
# add_node.sh
# 新增节点流程：载入已有顶级密钥，生成新节点密钥对与授权证书，克隆项目，放置配置文件，启动服务。
set -e
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/gen_keys.sh"

check_deps
ask_ipfs

# 步骤 1: 载入已有顶级密钥
mkdir -p "$KEY_DIR"

read -r -p "请输入顶级私钥路径 (private_key_top.pem): " TOP_PRIV
read -r -p "请输入顶级公钥路径 (public_key_top.pem): " TOP_PUB
TOP_PRIV="${TOP_PRIV/#\~/$HOME}"
TOP_PUB="${TOP_PUB/#\~/$HOME}"

if [ ! -f "$TOP_PRIV" ] || [ ! -f "$TOP_PUB" ]; then
    echo "错误：密钥文件不存在，请检查路径。"
    exit 1
fi
echo "==> 已确认顶级密钥"

# 步骤 2: 生成节点密钥对与授权证书
echo "==> 生成节点密钥对与授权证书..."
gen_node "$TOP_PRIV" "$KEY_DIR"

# 步骤 3: 克隆项目
if [ -d "$REPO_DIR/.git" ]; then
    echo "==> 项目已存在，拉取最新代码..."
    git -C "$REPO_DIR" pull
else
    echo "==> 克隆 BlockBase 项目..."
    git clone https://github.com/derek44554/BlockBase.git "$REPO_DIR"
fi

# 步骤 4: 放置密钥和配置文件
echo "==> 放置密钥和配置文件..."
mkdir -p "$REPO_DIR/resources"
cp "$KEY_DIR/node.yml"         "$REPO_DIR/node.yml"
cp "$KEY_DIR/private_key.pem"  "$REPO_DIR/resources/private_key.pem"
cp "$KEY_DIR/public_key.pem"   "$REPO_DIR/resources/public_key.pem"
cp "$TOP_PUB"                  "$REPO_DIR/resources/public_key_top.pem"
cp "$KEY_DIR/signature.yml"    "$REPO_DIR/resources/signature.yml"

# 步骤 5: App 配置密钥
generate_identity

# 步骤 6: Docker
setup_ipfs
echo "==> 启动服务..."
DOCKER=$(command -v docker || find /usr /usr/local -name docker -type f 2>/dev/null | head -1)
$DOCKER compose -f "$REPO_DIR/docker-compose.yml" up -d 2>/dev/null || \
    docker-compose -f "$REPO_DIR/docker-compose.yml" up -d

print_result
