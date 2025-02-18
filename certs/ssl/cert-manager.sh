#!/bin/bash

# 设置时区为上海时间
export TZ='Asia/Shanghai'

# 定义颜色变量
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 检查是否为root用户
check_root() {
  if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}错误: 请使用root权限运行此脚本${RESET}"
    exit 1
  fi
}

# 初始化 acme.sh
init_acme() {
  echo -e "${YELLOW}正在初始化 acme.sh...${RESET}"

  echo -e "${YELLOW}请选择证书颁发机构:${RESET}"
  echo "1. ZeroSSL (默认)"
  echo "2. Let's Encrypt"
  read -r -p "请选择 [1-2]: " ca_choice

  echo -e "${YELLOW}请输入您的邮箱地址（用于注册账户-随意填）:${RESET}"
  read -r email

  case $ca_choice in
  1)
    ~/.acme.sh/acme.sh --register-account -m "$email" --server zerossl
    ;;
  2)
    ~/.acme.sh/acme.sh --register-account -m "$email" --server letsencrypt
    ;;
  *)
    echo -e "${YELLOW}未选择，使用默认的 ZeroSSL${RESET}"
    ~/.acme.sh/acme.sh --register-account -m "$email" --server zerossl
    ;;
  esac
}

# 检查并安装依赖
install_dependencies() {
  echo -e "${YELLOW}检查必要依赖...${RESET}"

  # 检查包管理器
  if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt-get"
  elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
  else
    echo -e "${RED}不支持的系统类型${RESET}"
    exit 1
  fi

  # 安装基础依赖
  $PKG_MANAGER update -y
  $PKG_MANAGER install -y curl socat cron

  # 安装acme.sh
  if [ ! -f ~/.acme.sh/acme.sh ]; then
    echo -e "${YELLOW}安装acme.sh...${RESET}"
    curl https://get.acme.sh | sh
    source ~/.bashrc
    ~/.acme.sh/acme.sh --upgrade --auto-upgrade
    init_acme
  fi
}

# 申请证书
issue_cert() {
  while true; do
    local domains=()
    local main_domain=""
    local server_param=""

    echo -e "${YELLOW}=== 申请新证书 ===${RESET}"
    echo -e "${YELLOW}1. 继续申请证书${RESET}"
    echo -e "${YELLOW}0. 返回主菜单${RESET}"
    read -r -p "请选择 [0-1]: " proceed_choice

    case $proceed_choice in
    0) return ;;
    1) ;;
    *)
      echo -e "${RED}无效的选择，请重试${RESET}"
      continue
      ;;
    esac

    # 选择证书颁发机构
    echo -e "${YELLOW}请选择证书颁发机构:${RESET}"
    echo "1. ZeroSSL (默认)"
    echo "2. Let's Encrypt"
    echo "0. 返回上一步"
    read -r -p "请选择 [0-2]: " ca_choice

    case $ca_choice in
    0) continue ;;
    1) server_param="--server zerossl" ;;
    2) server_param="--server letsencrypt" ;;
    *)
      echo -e "${YELLOW}未选择，使用默认的 ZeroSSL${RESET}"
      server_param="--server zerossl"
      ;;
    esac

    echo -e "${YELLOW}请输入主域名 (例如: example.com):${RESET}"
    read -r main_domain
    domains+=("$main_domain")

    while true; do
      echo -e "${YELLOW}是否添加更多域名？[y/n]:${RESET}"
      read -r more
      if [[ "$more" != "y" ]]; then
        break
      fi

      echo -e "${YELLOW}请输入额外域名 (例如: *.example.com 或 sub.example.com):${RESET}"
      read -r domain
      domains+=("$domain")
    done

    # 构建域名参数
    domain_params=""
    for domain in "${domains[@]}"; do
      domain_params="$domain_params -d $domain"
    done

    echo -e "${YELLOW}选择验证方式:${RESET}"
    echo "1. DNS验证 (支持泛域名)"
    echo "2. HTTP验证 (仅支持普通域名)"
    echo "0. 返回上一步"
    read -r -p "请选择 [0-2]: " auth_method

    case $auth_method in
    0) continue ;;
    1)
      echo -e "${YELLOW}选择DNS提供商:${RESET}"
      echo "1. Cloudflare"
      echo "2. Aliyun"
      echo "3. DNSPod"
      echo "0. 返回上一步"
      read -r -p "请选择 [0-3]: " dns_provider

      case $dns_provider in
      0) continue ;;
      1)
        echo -e "${YELLOW}请输入Cloudflare Global API Key:${RESET}"
        read -r cf_key
        echo -e "${YELLOW}请输入Cloudflare Email:${RESET}"
        read -r cf_email
        export CF_Key="$cf_key"
        export CF_Email="$cf_email"
        ~/.acme.sh/acme.sh --issue $domain_params --dns dns_cf $server_param --force
        ;;
      2)
        echo -e "${YELLOW}请输入Aliyun Access Key ID:${RESET}"
        read -r ali_key
        echo -e "${YELLOW}请输入Aliyun Access Key Secret:${RESET}"
        read -r ali_secret
        export Ali_Key="$ali_key"
        export Ali_Secret="$ali_secret"
        ~/.acme.sh/acme.sh --issue $domain_params --dns dns_ali $server_param --force
        ;;
      3)
        echo -e "${YELLOW}请输入DNSPod ID:${RESET}"
        read -r dp_id
        echo -e "${YELLOW}请输入DNSPod Token:${RESET}"
        read -r dp_key
        export DP_Id="$dp_id"
        export DP_Key="$dp_key"
        ~/.acme.sh/acme.sh --issue $domain_params --dns dns_dp $server_param --force
        ;;
      esac
      ;;
    2)
      ~/.acme.sh/acme.sh --issue $domain_params --webroot /var/www/html $server_param --force
      ;;
    esac
  done
}

# 续签证书
renew_cert() {
  echo -e "${YELLOW}正在检查并续签所有证书...${RESET}"
  ~/.acme.sh/acme.sh --renew-all
}

# 显示证书列表
list_certs() {
  echo -e "${YELLOW}已申请的证书列表:${RESET}"
  ~/.acme.sh/acme.sh --list
}

# 卸载证书
uninstall_cert() {
  while true; do
    echo -e "${YELLOW}=== 卸载证书 ===${RESET}"
    echo -e "${YELLOW}1. 继续卸载证书${RESET}"
    echo -e "${YELLOW}0. 返回主菜单${RESET}"
    read -r -p "请选择 [0-1]: " proceed_choice

    case $proceed_choice in
    0) return ;;
    1) ;;
    *)
      echo -e "${RED}无效的选择，请重试${RESET}"
      continue
      ;;
    esac

    echo -e "${YELLOW}请输入要卸载的域名 (输入 0 返回):${RESET}"
    read -r domain
    [ "$domain" = "0" ] && continue

    ~/.acme.sh/acme.sh --remove --domain "$domain" --ecc
    echo -e "${GREEN}证书已成功卸载${RESET}"

    echo -e "${YELLOW}是否继续卸载其他证书？[y/n]:${RESET}"
    read -r continue_choice
    [[ "$continue_choice" != "y" ]] && break
  done
}

# 安装证书到指定目录
install_cert() {
  while true; do
    echo -e "${YELLOW}=== 安装证书 ===${RESET}"
    echo -e "${YELLOW}1. 继续安装证书${RESET}"
    echo -e "${YELLOW}0. 返回主菜单${RESET}"
    read -r -p "请选择 [0-1]: " proceed_choice

    case $proceed_choice in
    0) return ;;
    1) ;;
    *)
      echo -e "${RED}无效的选择，请重试${RESET}"
      continue
      ;;
    esac

    echo -e "${YELLOW}已申请的证书列表:${RESET}"
    ~/.acme.sh/acme.sh --list

    echo -e "${YELLOW}请输入要安装的域名 (输入 0 返回):${RESET}"
    read -r domain
    [ "$domain" = "0" ] && continue

    echo -e "${YELLOW}请输入证书安装路径 (例如: /etc/nginx/ssl, 输入 0 返回):${RESET}"
    read -r install_path
    [ "$install_path" = "0" ] && continue

    # 检查目录是否存在，不存在则创建
    if [ ! -d "$install_path" ]; then
      mkdir -p "$install_path"
    fi

    echo -e "${YELLOW}请选择证书安装方式:${RESET}"
    echo "1. 标准安装 (RSA证书,兼容性好,适合普通网站)"
    echo "2. ECC证书安装 (椭圆曲线加密,性能更好,适合高性能要求场景)"
    echo "0. 返回上一步"
    read -r -p "请选择 [0-2]: " install_type

    case $install_type in
    0) continue ;;
    1)
      # 标准安装证书
      ~/.acme.sh/acme.sh --install-cert -d "$domain" \
        --key-file "$install_path/$domain.key" \
        --cert-file "$install_path/$domain.cer" \
        --fullchain-file "$install_path/$domain.crt" \
        --reloadcmd "echo '证书安装完成'"
      ;;
    2)
      # ECC证书安装
      ~/.acme.sh/acme.sh --install-cert -d "$domain" \
        --ecc \
        --key-file "$install_path/$domain.key" \
        --cert-file "$install_path/$domain.cer" \
        --fullchain-file "$install_path/$domain.crt" \
        --reloadcmd "echo '证书安装完成'"
      ;;
    esac

    if [ $? -eq 0 ]; then
      echo -e "${GREEN}证书已成功安装到 $install_path${RESET}"
      echo -e "${GREEN}证书文件:${RESET}"
      echo -e "私钥: $install_path/$domain.key"
      echo -e "证书: $install_path/$domain.cer"
      echo -e "证书链: $install_path/$domain.crt"
    else
      echo -e "${RED}证书安装失败${RESET}"
    fi
  done
}

# 主菜单
main_menu() {
  while true; do
    echo -e "\n${GREEN}=== SSL证书管理工具 ===${RESET}"
    echo "1. 申请新证书"
    echo "2. 续签所有证书"
    echo "3. 查看证书列表"
    echo "4. 卸载证书"
    echo "5. 安装证书到指定目录"
    echo "0. 退出"

    read -r -p "请选择操作 [1-5]: " choice

    case $choice in
    1)
      issue_cert
      ;;
    2)
      renew_cert
      ;;
    3)
      list_certs
      ;;
    4)
      uninstall_cert
      ;;
    5)
      install_cert
      ;;
    0)
      echo -e "${GREEN}感谢使用！${RESET}"
      exit 0
      ;;
    *)
      echo -e "${RED}无效的选择，请重试${RESET}"
      ;;
    esac
  done
}

# 主程序
check_root
install_dependencies
main_menu
