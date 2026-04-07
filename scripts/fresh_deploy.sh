#!/usr/bin/env bash
# fresh_deploy.sh
# 全新部署流程：生成顶级密钥对、节点密钥对与授权证书，克隆项目，放置配置文件，启动服务。
set -e
source "$SCRIPT_DIR/common.sh"

ask_ipfs

# 步骤 1: 生成顶级密钥对
mkdir -p "$KEY_DIR"
TOP_PRIV="$KEY_DIR/private_key_top.pem"
TOP_PUB="$KEY_DIR/public_key_top.pem"

echo "==> 安装 blocklink 依赖..."
pip install blocklink -q

if [ -f "$TOP_PRIV" ] && [ -f "$TOP_PUB" ]; then
    echo "==> 顶级密钥已存在，跳过生成"
else
    echo "==> 生成顶级 RSA 4096 密钥对..."
    python3 - <<PYEOF
from blocklink.adapters.key.key_loot import generate_and_save_rsa_keys
generate_and_save_rsa_keys(path="$KEY_DIR")
PYEOF
    chmod 600 "$TOP_PRIV"
fi

# 步骤 2: 生成节点密钥对与授权证书
echo "==> 生成节点密钥对与授权证书..."
python3 - <<PYEOF
import os
os.chdir("$KEY_DIR")
from blocklink.adapters.key.key_loot import generate_node
generate_node(private_key_top_path="$TOP_PRIV")
PYEOF
chmod 600 "$KEY_DIR/private_key.pem"

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
docker-compose -f "$REPO_DIR/docker-compose.yml" up -d

print_result
echo "   顶级私钥:    $TOP_PRIV"
echo "   顶级公钥:    $TOP_PUB"
echo "   ⚠️  请妥善保管顶级密钥，切勿泄露或上传到公共仓库！"
