#!/usr/bin/env bash
# gen_keys.sh
# 用 openssl 纯 shell 实现顶级密钥对生成与节点密钥对+授权证书生成，无需 Python/pip。

set -e

# ─── 生成顶级密钥对 ───────────────────────────────────────────────────────────
# 对应 Python: generate_and_save_rsa_keys(path)
gen_top_keys() {
    local dir="$1"
    mkdir -p "$dir"
    echo "==> 生成顶级 RSA 4096 密钥对..."
    openssl genrsa -out "$dir/private_key_top.pem" 4096 2>/dev/null
    openssl rsa -in "$dir/private_key_top.pem" \
        -pubout -out "$dir/public_key_top.pem" 2>/dev/null
    chmod 600 "$dir/private_key_top.pem"
    echo "    私钥: $dir/private_key_top.pem"
    echo "    公钥: $dir/public_key_top.pem"
}

# ─── 生成节点密钥对与授权证书 ─────────────────────────────────────────────────
# 对应 Python: generate_node(private_key_top_path, output_dir, permission_level, validity_days)
gen_node() {
    local top_priv="$1"   # 顶级私钥路径
    local out_dir="$2"    # 输出目录
    local perm="${3:-1}"  # 权限等级，默认 1
    local days="${4:-365}" # 有效天数，默认 365

    mkdir -p "$out_dir"

    # 1. 生成 BID（16字节随机hex）
    local node_bid
    node_bid=$(openssl rand -hex 16)
    local sig_bid
    sig_bid=$(openssl rand -hex 16)

    # 2. 计算有效期（UTC ISO8601）
    local validity
    validity=$(date -u -d "+${days} days" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
        || date -u -v "+${days}d" '+%Y-%m-%dT%H:%M:%SZ')  # macOS 兼容

    # 3. 生成节点 RSA 4096 密钥对
    echo "==> 生成节点 RSA 4096 密钥对..."
    openssl genrsa -out "$out_dir/private_key.pem" 4096 2>/dev/null
    openssl rsa -in "$out_dir/private_key.pem" \
        -pubout -out "$out_dir/public_key.pem" 2>/dev/null
    chmod 600 "$out_dir/private_key.pem"

    # 4. 提取节点公钥二进制（DER格式）用于签名消息
    local pub_der
    pub_der=$(openssl rsa -in "$out_dir/private_key.pem" \
        -pubout -outform DER 2>/dev/null | base64 | tr -d '\n')

    # 5. 读取公钥 PEM（去掉首尾行，合并为单行存入 YAML）
    local pub_pem
    pub_pem=$(cat "$out_dir/public_key.pem")

    # 6. 构建待签名消息：node_bid + " " + perm(2字节大端) + " " + validity + " " + pub_der_binary
    #    用 Python 一行构建二进制消息（仅用标准库，无需任何第三方包）
    local msg_file
    msg_file=$(mktemp)
    python3 - <<PYEOF
import sys, base64, struct
node_bid = "$node_bid".encode()
perm = struct.pack('>H', $perm)
validity = "$validity".encode()
pub_bin = base64.b64decode("$pub_der")
msg = node_bid + b" " + perm + b" " + validity + b" " + pub_bin
with open("$msg_file", "wb") as f:
    f.write(msg)
PYEOF

    # 7. 用顶级私钥签名（PSS + SHA3-256）
    local sig_b64
    sig_b64=$(openssl dgst -sha3-256 \
        -sigopt rsa_padding_mode:pss \
        -sigopt rsa_pss_saltlen:-1 \
        -sigopt rsa_mgf1_md:sha3-256 \
        -sign "$top_priv" \
        -binary "$msg_file" 2>/dev/null | base64 | tr -d '\n')
    rm -f "$msg_file"

    # 8. 写入 node.yml
    cat > "$out_dir/node.yml" <<EOF
bid: $node_bid
model: node
EOF

    # 9. 写入 signature.yml
    cat > "$out_dir/signature.yml" <<EOF
bid: $sig_bid
model: signature
signature: $sig_b64
owner: $node_bid
permission_level: $perm
validity_period: $validity
public_key_pem: |
$(echo "$pub_pem" | sed 's/^/  /')
EOF

    echo "    节点私钥: $out_dir/private_key.pem"
    echo "    节点公钥: $out_dir/public_key.pem"
    echo "    node.yml: $out_dir/node.yml"
    echo "    signature.yml: $out_dir/signature.yml"
}
