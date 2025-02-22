# SSL 证书管理工具

## 目录

1. [简介](#简介)
2. [功能特性](#功能特性)
3. [使用指南](#使用指南)
4. [注意事项](#注意事项)

## 功能特性

### 1. 证书申请

- 支持多种 CA 机构
  - ZeroSSL
  - Let's Encrypt
- 灵活的验证方式
  - DNS 验证
  - HTTP 验证
- 泛域名证书支持

### 2. 证书管理

- 自动化部署
  - 一键安装到指定目录
  - 定时自动续期
  - 证书状态监控
- 便捷操作
  - 证书查看
  - 证书卸载
  - 批量管理

### 3. DNS 集成

- 主流 DNS 服务商支持
  - Cloudflare
  - 阿里云 DNS
  - DNSPod
- API 自动化集成

## 注意事项

1. 需要 root 权限运行
2. 确保服务器能够访问互联网
3. DNS 验证需提前准备好 API 密钥
4. 建议定期备份证书
