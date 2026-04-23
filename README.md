# block_shell

[BlockBase](https://github.com/derek44554/BlockBase) 一键部署脚本，简化节点的安装、配置与管理流程。

## 快速开始

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/derek44554/block_shell/main/start.sh)
```

## 功能菜单

| 选项 | 说明 |
|------|------|
| 1) 全新部署 | 生成顶级密钥对、节点密钥，克隆项目并启动服务 |
| 2) 新增节点 | 使用已有顶级密钥生成新节点并部署 |
| 3) 启动已有节点 | 直接启动已部署的容器 |
| 4) 节点升级 | 拉取最新代码并重新构建 |
| 5) 开启 IPFS 存储 | 为已有节点启动 IPFS 容器并完成对接 |

## 密钥说明

- 全新部署时，顶级密钥对会保存在 `~/block_key/`，请妥善保管，切勿泄露
- 新增节点时，需提供已有顶级密钥的文件路径
