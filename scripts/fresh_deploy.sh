#!/usr/bin/env bash
# fresh_deploy.sh
# 全新部署流程：生成顶级密钥对、节点密钥对与授权证书，克隆项目，放置配置文件，启动服务。
set -e
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/gen_keys.sh"

ask_ipfs
check_deps

# 步骤 1: 生成顶级密钥对
TOP_PRIV="$KEY_DIR/private_key_top.pem"
TOP_PUB="$KEY_DIR/public_key_top.pem"

if [ -f "$TOP_PRIV" ] && [ -f "$TOP_PUB" ]; then
    echo "==> 顶级密钥已存在，跳过生成"
else
    gen_top_keys "$KEY_DIR"
fi

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

# 步骤 6: 写入 IPFS 配置（如开启）
setup_ipfs_config

# 步骤 7: 清理 block_key 中的节点临时文件，只保留顶级密钥
echo "==> 清理节点临时文件..."
rm -f "$KEY_DIR/node.yml" "$KEY_DIR/signature.yml" \
      "$KEY_DIR/private_key.pem" "$KEY_DIR/public_key.pem"

# 步骤 8: 启动 Docker
echo "==> 启动服务..."
start_docker

print_result
echo "   顶级私钥:    $TOP_PRIV"
echo "   顶级公钥:    $TOP_PUB"
echo "   ⚠️  请妥善保管顶级私钥，切勿泄露或上传到公共仓库！"
