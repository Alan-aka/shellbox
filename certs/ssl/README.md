## 核心功能

1. 证书申请

   - 支持 ZeroSSL 和 Let's Encrypt
   - 支持 DNS 验证和 HTTP 验证
   - 支持泛域名证书

2. 证书管理

   - 一键安装到指定目录
   - 自动续期
   - 证书查看与卸载

3. DNS 集成
   - Cloudflare
   - 阿里云 DNS
   - DNSPod

## 特色功能

1. 操作便捷

   - 交互式操作界面
   - 傻瓜式配置流程
   - 自动依赖检查安装

2. 安全可靠

   - 自动权限检查
   - 证书安全存储
   - 关键信息加密处理

3. 灵活扩展
   - 支持 RSA/ECC 双证书体系
   - 支持多域名绑定
   - 支持批量操作

## 如何使用？

1. 安装脚本

   ```bash
   wget -N https://raw.githubusercontent.com/Alan-aka/shellbox/main/certs/ssl/cert-manager.sh
   chmod +x cert-manager.sh
   ```

2. 运行脚本

   ```bash
   ./cert-manager.sh
   ```

3. 按照交互提示操作即可完成证书申请、安装、续期等操作

## 注意事项

1. 需要 root 权限运行
2. 确保服务器能够访问互联网
3. DNS 验证需提前准备好 API 密钥
4. 建议定期备份证书
