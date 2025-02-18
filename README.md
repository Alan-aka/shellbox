# shellbox

一个简化日常任务的 Shell 脚本工具箱

## 简介

shellbox 是一个用于简化日常命令行任务的工具集合，提供了一系列实用的 shell 脚本来提高工作效率。主要包含证书管理、Git 账号管理等核心功能。

## 功能特性

### 证书管理 (cert-manager.sh)

- 支持多种 SSL 证书颁发机构 (ZeroSSL、Let's Encrypt)
- 自动化证书申请、续签和安装
- 支持 DNS 验证和 HTTP 验证
- 支持多域名证书和泛域名证书
- 集成主流 DNS 服务商 API (Cloudflare、Aliyun、DNSPod)

#### 使用

```bash
# 安装运行
bash <(curl -sSL https://is.gd/dpdrPB)
# 或者
source <(curl -sSL https://is.gd/dpdrPB)
# 以上两种方式任选其一即可
```

### Git 账号管理 (git-account-manager.sh)

- 多 GitHub 账号管理
- SSH 密钥自动配置
- 项目工作区管理
- 分支管理与操作
  - 分支创建、切换、合并
  - 远程分支拉取与推送
  - 上游分支设置
- 提交管理
  - 智能暂存区管理
  - 提交信息规范化
  - 提交历史修改
- 代码同步
  - 多种拉取策略(普通/变基/强制)
  - 自动储藏本地更改
  - 冲突解决辅助

#### 使用

```bash
# 安装运行
bash <(curl -sSL https://is.gd/bxsNEY)
# 或者
source <(curl -sSL https://is.gd/bxsNEY)
# 以上两种方式任选其一即可
```

## 注意事项

- 证书管理需要 root 权限
- 确保系统已安装基础依赖
- Git 账号管理建议在用户目录下使用
