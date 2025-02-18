#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置文件路径
CONFIG_FILE="$HOME/.github_accounts"
SSH_CONFIG="$HOME/.ssh/config"

# 新增项目配置文件
PROJECT_CONFIG="$HOME/.github_projects"
WORKSPACE_ROOT="$HOME/Workspaces/GitHub" # 工作空间根目录

# 确保配置文件存在
touch "$CONFIG_FILE"
mkdir -p "$HOME/.ssh"
touch "$SSH_CONFIG"

# 确保配置文件和工作目录存在
touch "$PROJECT_CONFIG"
mkdir -p "$WORKSPACE_ROOT"

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}      _    _                     _    _                     ${NC}"
    echo -e "${BLUE}     / \  | | __ _ _ __        / \  | | ____ _            ${NC}"
    echo -e "${BLUE}    / _ \ | |/ _\` | '_ \      / _ \ | |/ / _\` |           ${NC}"
    echo -e "${BLUE}   / ___ \| | (_| | | | |    / ___ \|   < (_| |           ${NC}"
    echo -e "${BLUE}  /_/   \_\_|\__,_|_| |_|   /_/   \_\_|\_\__,_|           ${NC}"
    echo -e "${BLUE}                                                           ${NC}"
    echo -e "${BLUE}        ${GREEN}GitHub 账号智能管理工具 ${RED}[MacOS专属]${NC}${BLUE}        ${NC}"
    echo ""
}

# 主菜单
show_main_menu() {
    show_banner
    echo -e "1) ${YELLOW}账号管理${NC}"
    echo -e "2) ${YELLOW}项目管理${NC}"
    echo -e "3) ${YELLOW}项目操作${NC}"
    echo -e "4) ${YELLOW}SSH密钥管理${NC}"
    echo -e "5) ${YELLOW}测试SSH连接${NC}"
    echo -e "6) ${YELLOW}查看当前配置${NC}"
    echo -e "7) ${YELLOW}查看原始配置文件${NC}"
    echo -e "8) ${YELLOW}修改当前路径Git配置${NC}"
    echo -e "0) ${RED}退出${NC}"
    echo ""
    read -p "请选择操作 [0-8]: " choice

    case $choice in
    1) account_management_menu ;;
    2) project_management_menu ;;
    3) project_operations_menu ;;
    4) ssh_key_management ;;
    5) test_connection ;;
    6) view_configurations ;;
    7) view_raw_config ;;
    8) configure_current_directory ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效选择${NC}" && sleep 2 && show_main_menu ;;
    esac
}

# 账号管理菜单
account_management_menu() {
    show_banner
    echo -e "1) ${YELLOW}添加新账号${NC}"
    echo -e "2) ${YELLOW}删除账号${NC}"
    echo -e "3) ${YELLOW}返回主菜单${NC}"
    echo ""
    read -p "请选择操作 [1-3]: " choice

    case $choice in
    1) add_account ;;
    2) delete_account ;;
    3) show_main_menu ;;
    *) echo -e "${RED}无效选择${NC}" && sleep 2 && account_management_menu ;;
    esac
}

# 添加新账号
add_account() {
    show_banner
    echo -e "${YELLOW}添加新GitHub账号${NC}"
    echo "------------------------"

    # 检查现有账号
    if [[ -s "$CONFIG_FILE" ]]; then
        echo -e "${GREEN}当前已配置的账号：${NC}"
        while IFS=';' read -r existing_name existing_username existing_email; do
            echo -e "• ${BLUE}$existing_name${NC} ($existing_username)"
        done <"$CONFIG_FILE"
        echo "------------------------"
    fi

    read -p "输入账号名称: " account_name

    # 检查账号名称是否已存在
    if grep -q "^$account_name;" "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}错误：账号名称 '$account_name' 已存在！${NC}"
        echo -e "请选择操作："
        echo -e "1) ${YELLOW}使用其他名称${NC}"
        echo -e "2) ${YELLOW}更新现有账号${NC}"
        echo -e "3) ${RED}取消操作${NC}"
        read -p "请选择 [1-3]: " choice

        case $choice in
        1)
            read -p "请输入新的账号名称: " account_name
            if grep -q "^$account_name;" "$CONFIG_FILE" 2>/dev/null; then
                echo -e "${RED}错误：新账号名称依然存在！${NC}"
                read -p "按回车键返回..."
                account_management_menu
                return
            fi
            ;;
        2)
            # 获取现有账号信息用于显示
            existing_info=$(grep "^$account_name;" "$CONFIG_FILE")
            IFS=';' read -r _ old_username old_email <<<"$existing_info"
            echo -e "\n${YELLOW}当前账号信息：${NC}"
            echo "用户名: $old_username"
            echo "邮箱: $old_email"
            echo -e "\n${YELLOW}请输入新的信息：${NC}"
            ;;
        3)
            echo -e "${YELLOW}操作已取消${NC}"
            read -p "按回车键返回..."
            account_management_menu
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            read -p "按回车键返回..."
            account_management_menu
            return
            ;;
        esac
    fi

    read -p "输入GitHub用户名: " github_username
    read -p "输入GitHub邮箱: " github_email

    # 检查用户名是否已被其他账号使用
    if grep -q ":$github_username;" "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}警告：GitHub用户名 '$github_username' 已被其他账号使用！${NC}"
        read -p "是否继续？(y/n): " continue_add
        if [[ $continue_add != "y" ]]; then
            echo -e "${YELLOW}操作已取消${NC}"
            read -p "按回车键返回..."
            account_management_menu
            return
        fi
    fi

    # 如果是更新现有账号，则删除旧配置
    if [[ $choice == "2" ]]; then
        sed -i '' "/^$account_name;/d" "$CONFIG_FILE"
        echo -e "${GREEN}正在更新账号信息...${NC}"
    fi

    # 保存账号信息
    echo "$account_name;$github_username;$github_email" >>"$CONFIG_FILE"

    # 生成SSH密钥
    echo -e "\n${YELLOW}是否为该账号生成SSH密钥? (y/n)${NC}"
    read -p "> " generate_ssh

    if [[ $generate_ssh == "y" ]]; then
        # 检查是否已存在SSH密钥
        if [[ -f "$HOME/.ssh/id_rsa_$account_name" ]]; then
            echo -e "${YELLOW}警告：SSH密钥已存在${NC}"
            echo -e "1) ${YELLOW}重新生成${NC}"
            echo -e "2) ${YELLOW}保留现有密钥${NC}"
            read -p "请选择 [1-2]: " key_choice

            case $key_choice in
            1)
                rm -f "$HOME/.ssh/id_rsa_$account_name" "$HOME/.ssh/id_rsa_$account_name.pub"
                ssh-keygen -t rsa -b 4096 -C "$github_email" -f "$HOME/.ssh/id_rsa_$account_name" -N ""
                ;;
            2)
                echo -e "${GREEN}保留现有SSH密钥${NC}"
                ;;
            *)
                echo -e "${RED}无效的选择，保留现有密钥${NC}"
                ;;
            esac
        else
            # 生成新的SSH密钥
            ssh-keygen -t rsa -b 4096 -C "$github_email" -f "$HOME/.ssh/id_rsa_$account_name" -N ""
        fi

        # 更新SSH配置
        if ! grep -q "Host github-$account_name" "$SSH_CONFIG" 2>/dev/null; then
            # 确保配置文件末尾有换行
            if [[ -s "$SSH_CONFIG" ]]; then
                echo "" >>"$SSH_CONFIG"
            fi

            cat >>"$SSH_CONFIG" <<EOF
Host github-$account_name
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_$account_name
    AddKeysToAgent yes
    UseKeychain yes

EOF
        fi

        # 自动添加到 ssh-agent
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add -q "$HOME/.ssh/id_rsa_$account_name"

        echo -e "\n${GREEN}SSH密钥已生成。请将以下公钥添加到GitHub账号：${NC}"
        cat "$HOME/.ssh/id_rsa_$account_name.pub"
    fi

    echo -e "\n${GREEN}账号$(if [[ $choice == "2" ]]; then echo "更新"; else echo "添加"; fi)成功！${NC}"
    read -p "按回车键继续..."
    show_main_menu
}

# 删除账号
delete_account() {
    show_banner
    echo -e "${YELLOW}删除GitHub账号${NC}"
    echo "------------------------"

    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${RED}暂无配置的账号${NC}"
        read -p "按回车键继续..."
        account_management_menu
        return
    fi

    # 显示可删除的账号
    echo "可删除的账号："
    declare -a accounts=()
    while IFS=';' read -r account_name github_username github_email; do
        accounts+=("$account_name")
        echo "$((${#accounts[@]})) $account_name ($github_username)"
    done <"$CONFIG_FILE"

    read -p "选择要删除的账号编号: " account_number

    if [[ $account_number -le ${#accounts[@]} && $account_number -gt 0 ]]; then
        selected_account=${accounts[$((account_number - 1))]}

        # 确认删除
        read -p "确认删除账号 '$selected_account'? (y/n): " confirm_delete
        if [[ $confirm_delete == "y" ]]; then
            # 删除账号配置
            sed -i '' "/^$selected_account;/d" "$CONFIG_FILE"

            # 删除相关的SSH密钥
            if [[ -f "$HOME/.ssh/id_rsa_$selected_account" ]]; then
                echo -e "\n${YELLOW}是否删除关联的SSH密钥?${NC}"
                echo -e "- $HOME/.ssh/id_rsa_$selected_account"
                echo -e "- $HOME/.ssh/id_rsa_$selected_account.pub"
                read -p "删除SSH密钥? (y/n): " delete_keys

                if [[ $delete_keys == "y" ]]; then
                    # 从 ssh-agent 中移除密钥
                    ssh-add -d "$HOME/.ssh/id_rsa_$selected_account" 2>/dev/null

                    # 删除密钥文件
                    rm -f "$HOME/.ssh/id_rsa_$selected_account" "$HOME/.ssh/id_rsa_$selected_account.pub"

                    # 从SSH配置中移除相关配置
                    sed -i '' "/Host github-$selected_account/,/UseKeychain yes/d" "$SSH_CONFIG"

                    echo -e "${GREEN}SSH密钥已删除${NC}"
                fi
            fi

            # 检查并处理关联的项目
            if [[ -s "$PROJECT_CONFIG" ]]; then
                echo -e "\n${YELLOW}检查关联的项目...${NC}"
                projects_found=false
                while IFS=';' read -r project_name account_name repo_url project_path; do
                    if [[ "$account_name" == "$selected_account" ]]; then
                        projects_found=true
                        echo "发现关联项目: $project_name"
                    fi
                done <"$PROJECT_CONFIG"

                if [[ "$projects_found" == true ]]; then
                    echo -e "\n${YELLOW}是否删除关联的项目配置?${NC}"
                    read -p "删除项目配置? (y/n): " delete_projects
                    if [[ $delete_projects == "y" ]]; then
                        sed -i '' "/^.*;$selected_account;/d" "$PROJECT_CONFIG"
                        echo -e "${GREEN}关联的项目配置已删除${NC}"
                    fi
                fi
            fi

            echo -e "\n${GREEN}账号已成功删除！${NC}"
        else
            echo -e "${YELLOW}操作已取消${NC}"
        fi
    else
        echo -e "${RED}无效的选择${NC}"
    fi

    read -p "按回车键继续..."
    account_management_menu
}

# 查看当前配置
view_configurations() {
    show_banner
    echo -e "${YELLOW}当前配置信息${NC}"
    echo "------------------------"

    # 显示账号配置
    echo -e "${GREEN}已配置的账号：${NC}"
    if [[ -s "$CONFIG_FILE" ]]; then
        while IFS=';' read -r account_name github_username github_email; do
            echo -e "\n${BLUE}▶ 账号: $account_name${NC}"
            echo -e "  • 用户名: $github_username"
            echo -e "  • 邮箱: $github_email"

            # 检查并显示对应的 SSH 密钥状态
            if [[ -f "$HOME/.ssh/id_rsa_$account_name" ]]; then
                echo -e "  • SSH私钥: ${GREEN}已存在${NC} (~/.ssh/id_rsa_$account_name)"
                if [[ -f "$HOME/.ssh/id_rsa_$account_name.pub" ]]; then
                    echo -e "  • SSH公钥: ${GREEN}已存在${NC} (~/.ssh/id_rsa_$account_name.pub)"
                else
                    echo -e "  • SSH公钥: ${RED}未找到${NC}"
                fi

                # 检查密钥是否已添加到 ssh-agent
                if ssh-add -l | grep -q "$HOME/.ssh/id_rsa_$account_name"; then
                    echo -e "  • SSH-Agent: ${GREEN}已加载${NC}"
                else
                    echo -e "  • SSH-Agent: ${YELLOW}未加载${NC}"
                fi
            else
                echo -e "  • SSH密钥: ${YELLOW}未生成${NC}"
            fi
            echo -e "  ------------------------"
        done <"$CONFIG_FILE"
    else
        echo -e "${YELLOW}暂无配置的账号${NC}"
        echo "------------------------"
    fi

    # 显示 SSH 配置
    echo -e "\n${GREEN}SSH配置详情：${NC}"
    if [[ -s "$SSH_CONFIG" ]]; then
        echo -e "${BLUE}▶ SSH配置文件：${NC} $SSH_CONFIG"
        echo -e "\n${YELLOW}配置内容：${NC}"
        while IFS=';' read -r line; do
            if [[ $line =~ ^Host ]]; then
                echo -e "\n${BLUE}$line${NC}"
            elif [[ $line =~ ^[[:space:]]*HostName ]]; then
                echo -e "  • ${GREEN}$line${NC}"
            elif [[ -n $line ]]; then
                echo -e "  • $line"
            fi
        done <"$SSH_CONFIG"
    else
        echo -e "${YELLOW}SSH配置文件为空${NC}"
    fi

    # 显示全局 Git 配置
    echo -e "\n${GREEN}全局Git配置：${NC}"
    echo -e "${BLUE}▶ 当前配置${NC}"
    echo -e "  • 用户名: $(git config --global user.name 2>/dev/null || echo '未设置')"
    echo -e "  • 邮箱: $(git config --global user.email 2>/dev/null || echo '未设置')"
    echo -e "  • 默认分支: $(git config --global init.defaultBranch 2>/dev/null || echo '未设置')"
    if [[ -n $(git config --global core.sshCommand) ]]; then
        echo -e "  • SSH命令: $(git config --global core.sshCommand)"
    fi

    read -p "按回车键返回主菜单..."
    show_main_menu
}

# SSH密钥管理
ssh_key_management() {
    show_banner
    echo -e "${YELLOW}SSH密钥管理${NC}"
    echo "------------------------"
    echo -e "1) ${YELLOW}查看现有SSH密钥${NC}"
    echo -e "2) ${YELLOW}生成新SSH密钥${NC}"
    echo -e "3) ${YELLOW}删除SSH密钥${NC}"
    echo -e "4) ${YELLOW}返回主菜单${NC}"

    read -p "请选择操作 [1-4]: " choice

    case $choice in
    1)
        echo -e "\n${GREEN}现有SSH密钥：${NC}"
        ls -l "$HOME/.ssh" | grep "id_rsa"
        ;;
    2)
        read -p "输入密钥标识（如：github-personal）: " key_name
        read -p "输入关联的邮箱: " key_email

        # 使用 -N "" 参数生成无密码的密钥
        ssh-keygen -t rsa -b 4096 -C "$key_email" -f "$HOME/.ssh/id_rsa_$key_name" -N ""

        # 更新SSH配置
        if ! grep -q "Host github-$key_name" "$SSH_CONFIG" 2>/dev/null; then
            cat >>"$SSH_CONFIG" <<EOF

Host github-$key_name
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa_$key_name
    AddKeysToAgent yes
    UseKeychain yes
EOF
        fi

        # 自动添加到 ssh-agent
        eval "$(ssh-agent -s)" >/dev/null 2>&1
        ssh-add -q "$HOME/.ssh/id_rsa_$key_name"

        echo -e "\n${GREEN}密钥已生成。公钥内容：${NC}"
        cat "$HOME/.ssh/id_rsa_$key_name.pub"
        ;;
    3)
        echo -e "\n${YELLOW}可删除的SSH密钥：${NC}"
        # 只列出私钥文件（不包含.pub）并编号
        ls -1 "$HOME/.ssh" | grep "id_rsa" | grep -v "\.pub$" | nl
        echo -e "\n${YELLOW}输入要删除的密钥编号（多个编号用空格分隔）：${NC}"
        read -p "> " key_numbers

        # 确认删除
        echo -e "\n${RED}将删除以下密钥：${NC}"
        for num in $key_numbers; do
            key_to_delete=$(ls -1 "$HOME/.ssh" | grep "id_rsa" | grep -v "\.pub$" | sed -n "${num}p")
            if [[ -n "$key_to_delete" ]]; then
                echo "$key_to_delete"
            fi
        done

        read -p "确认删除这些密钥？(y/n): " confirm
        if [[ $confirm == "y" ]]; then
            for num in $key_numbers; do
                key_to_delete=$(ls -1 "$HOME/.ssh" | grep "id_rsa" | grep -v "\.pub$" | sed -n "${num}p")
                if [[ -n "$key_to_delete" ]]; then
                    # 从 ssh-agent 中移除密钥
                    ssh-add -d "$HOME/.ssh/$key_to_delete" 2>/dev/null

                    # 删除密钥文件（私钥和公钥）
                    rm -f "$HOME/.ssh/$key_to_delete" "$HOME/.ssh/$key_to_delete.pub"

                    # 从 SSH 配置文件中移除相关配置
                    key_name=$(echo "$key_to_delete" | sed 's/id_rsa_//')
                    sed -i '' "/Host github-$key_name/,/UseKeychain yes/d" "$SSH_CONFIG"

                    echo -e "${GREEN}已删除密钥：$key_to_delete${NC}"
                else
                    echo -e "${RED}无效的选择：$num${NC}"
                fi
            done
        else
            echo -e "${YELLOW}操作已取消${NC}"
        fi
        ;;
    4)
        show_main_menu
        return
        ;;
    esac

    read -p "按回车键继续..."
    ssh_key_management
}

# 测试连接
test_connection() {
    show_banner
    echo -e "${YELLOW}测试GitHub连接${NC}"
    echo "------------------------"

    # 检查是否有配置的账号
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${RED}错误：未找到任何配置的账号！${NC}"
        read -p "按回车键返回..."
        show_main_menu
        return
    fi

    # 显示可选择的账号
    echo -e "${GREEN}选择要测试的账号：${NC}"
    declare -a accounts=()
    declare -a usernames=()
    declare -a emails=()

    while IFS=';' read -r account_name github_username github_email; do
        accounts+=("$account_name")
        usernames+=("$github_username")
        emails+=("$github_email")
        echo "$((${#accounts[@]})) $account_name ($github_username)"
    done <"$CONFIG_FILE"
    echo -e "0) ${YELLOW}测试所有账号${NC}"

    read -p "请选择账号编号 [0-${#accounts[@]}]: " choice

    # 测试指定账号或所有账号
    if [[ $choice == "0" ]]; then
        echo -e "\n${GREEN}测试所有配置的账号...${NC}"
        for ((i = 0; i < ${#accounts[@]}; i++)); do
            test_single_account "${accounts[$i]}" "${usernames[$i]}" "${emails[$i]}"
        done
    elif [[ $choice -le ${#accounts[@]} && $choice -gt 0 ]]; then
        index=$((choice - 1))
        test_single_account "${accounts[$index]}" "${usernames[$index]}" "${emails[$index]}"
    else
        echo -e "${RED}无效的选择！${NC}"
    fi

    # 显示常见问题解决方案
    echo -e "\n${YELLOW}常见问题解决方案：${NC}"
    echo -e "1. 如果连接失败，请检查："
    echo -e "   • SSH密钥是否已添加到GitHub账号"
    echo -e "   • SSH配置文件是否正确 (~/.ssh/config)"
    echo -e "   • SSH密钥权限是否正确 (600)"
    echo -e "2. 修复SSH密钥权限："
    echo -e "   chmod 600 ~/.ssh/id_rsa_*"
    echo -e "3. 重新加载SSH密钥："
    echo -e "   ssh-add -D  # 清除所有密钥"
    echo -e "   ssh-add ~/.ssh/id_rsa_*  # 重新添加密钥"
    echo -e "4. 验证SSH配置："
    echo -e "   ssh -vT git@github.com  # 显示详细连接信息"

    read -p "按回车键返回主菜单..."
    show_main_menu
}

# 测试单个账号的连接
test_single_account() {
    local account_name="$1"
    local github_username="$2"
    local github_email="$3"

    echo -e "\n${BLUE}▶ 测试账号: $account_name ($github_username)${NC}"

    # 检查SSH密钥权限
    local key_perms=$(stat -f "%Lp" "$HOME/.ssh/id_rsa_$account_name")
    if [[ "$key_perms" != "600" ]]; then
        echo -e "${YELLOW}警告：SSH密钥权限不正确 (当前: $key_perms, 应为: 600)${NC}"
        echo -e "是否修复权限？(y/n)"
        read -p "> " fix_perms
        if [[ $fix_perms == "y" ]]; then
            chmod 600 "$HOME/.ssh/id_rsa_$account_name"
            echo -e "${GREEN}权限已修复${NC}"
        fi
    fi

    # 确保SSH-Agent正在运行
    if ! pgrep -q ssh-agent; then
        eval "$(ssh-agent -s)" >/dev/null
    fi

    # 检查密钥是否已添加到SSH-Agent
    if ! ssh-add -l | grep -q "$HOME/.ssh/id_rsa_$account_name"; then
        echo -e "${YELLOW}添加SSH密钥到ssh-agent...${NC}"
        ssh-add -q "$HOME/.ssh/id_rsa_$account_name"
    fi

    # 测试连接
    echo -e "${GREEN}测试SSH连接...${NC}"
    if ssh -T "github-$account_name" 2>&1 | grep -q "success"; then
        echo -e "${GREEN}✓ 连接成功！${NC}"

        # 获取API速率限制信息
        echo -e "\n${BLUE}检查API限制：${NC}"
        curl -s -I "https://api.github.com/users/$github_username" | grep "X-RateLimit"

        # 测试Git配置
        echo -e "\n${BLUE}测试Git配置：${NC}"
        echo -e "• 用户名: $github_username"
        echo -e "• 邮箱: $github_email"
        echo -e "• SSH命令: ssh -i ~/.ssh/id_rsa_$account_name"
    else
        echo -e "${RED}✗ 连接失败！${NC}"
        echo -e "\n${YELLOW}诊断信息：${NC}"
        ssh -Tv "github-$account_name" 2>&1 | grep -E "debug1|Authenticated|Permission|denied|error"
    fi

    # 显示分隔线
    echo -e "${BLUE}------------------------${NC}"
}

# 项目管理菜单
project_management_menu() {
    show_banner
    echo -e "${YELLOW}项目管理${NC}"
    echo "------------------------"
    echo -e "1) ${YELLOW}添加新项目${NC}"
    echo -e "2) ${YELLOW}查看项目列表${NC}"
    echo -e "3) ${YELLOW}删除项目配置${NC}"
    echo -e "4) ${YELLOW}查看项目Git信息${NC}"
    echo -e "5) ${YELLOW}返回主菜单${NC}"

    read -p "请选择操作 [1-5]: " choice

    case $choice in
    1) add_project ;;
    2) list_projects ;;
    3) delete_project ;;
    4) view_project_git_info ;;
    5) show_main_menu ;;
    *) echo -e "${RED}无效选择${NC}" && sleep 2 && project_management_menu ;;
    esac
}

# 添加新项目
add_project() {
    show_banner
    echo -e "${YELLOW}添加新项目${NC}"
    echo "------------------------"

    # 检查是否有可用账号
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "${RED}暂无配置的账号，请先添加账号！${NC}"
        read -p "按回车键继续..."
        project_management_menu
        return
    fi

    # 输入项目别名
    while true; do
        read -p "输入项目别名(用于快速操作): " project_alias
        # 检查别名格式
        if [[ ! $project_alias =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            echo -e "${RED}错误：别名必须以字母开头，只能包含字母、数字、下划线和连字符${NC}"
            continue
        fi
        # 检查别名是否已存在
        if grep -q "^$project_alias;" "$PROJECT_CONFIG" 2>/dev/null; then
            echo -e "${RED}错误：别名 '$project_alias' 已存在！${NC}"
            continue
        fi
        break
    done

    # 输入项目名称（只询问一次）
    read -p "输入项目名称: " project_name

    # 显示可用账号并存储到数组
    echo -e "${GREEN}可用账号：${NC}"
    declare -a accounts=()
    declare -a usernames=()
    declare -a emails=()
    while IFS=';' read -r account_name github_username github_email; do
        accounts+=("$account_name")
        usernames+=("$github_username")
        emails+=("$github_email")
        echo "$((${#accounts[@]})) $account_name ($github_username)"
    done <"$CONFIG_FILE"

    # 选择账号
    read -p "选择关联的账号编号 [1-${#accounts[@]}]: " account_number
    if [[ ! $account_number =~ ^[0-9]+$ ]] || [[ $account_number -lt 1 ]] || [[ $account_number -gt ${#accounts[@]} ]]; then
        echo -e "${RED}无效的账号选择！${NC}"
        read -p "按回车键继续..."
        project_management_menu
        return
    fi

    account_name=${accounts[$((account_number - 1))]}
    github_username=${usernames[$((account_number - 1))]}
    github_email=${emails[$((account_number - 1))]}

    # 输入项目信息
    # read -p "输入项目名称: " project_name

    # 修改仓库地址选项部分
    echo -e "\n${YELLOW}配置仓库地址：${NC}"
    # 自动生成SSH地址
    repo_url="git@github.com:$github_username/$project_name.git"
    echo -e "将使用SSH地址: ${GREEN}$repo_url${NC}"

    # 选择项目保存位置
    echo -e "\n${YELLOW}选择项目保存位置：${NC}"
    echo -e "1) 默认位置 (${GREEN}$WORKSPACE_ROOT/$account_name/$project_name${NC})"
    echo -e "2) 自定义位置"
    read -p "请选择 [1-2]: " location_choice

    case $location_choice in
    1)
        project_path="$WORKSPACE_ROOT/$account_name/$project_name"
        ;;
    2)
        read -p "请输入完整的项目路径: " custom_path
        if [[ -z "$custom_path" ]]; then
            echo -e "${RED}路径不能为空，将使用默认路径${NC}"
            project_path="$WORKSPACE_ROOT/$account_name/$project_name"
        else
            # 展开 ~ 到实际的家目录
            project_path="${custom_path/#\~/$HOME}"
            # 确保路径末尾包含项目名称
            if [[ "$(basename "$project_path")" != "$project_name" ]]; then
                project_path="$project_path/$project_name"
            fi
        fi
        ;;
    *)
        echo -e "${RED}无效的选择，将使用默认路径${NC}"
        project_path="$WORKSPACE_ROOT/$account_name/$project_name"
        ;;
    esac

    # 规范化路径
    project_path=$(echo "$project_path" | sed 's/://')

    # 检查项目配置是否已存在
    if grep -q "^$project_name;$account_name;" "$PROJECT_CONFIG"; then
        echo -e "${RED}项目配置已存在！${NC}"
        echo -e "当前配置："
        grep "^$project_name;$account_name;" "$PROJECT_CONFIG"
        echo -e "\n${YELLOW}选择操作：${NC}"
        echo "1) 更新现有配置"
        echo "2) 取消操作"
        read -p "请选择 [1-2]: " update_choice

        case $update_choice in
        1)
            sed -i '' "/^$project_name;$account_name;/d" "$PROJECT_CONFIG"
            ;;
        2)
            echo -e "${YELLOW}操作已取消${NC}"
            read -p "按回车键继续..."
            project_management_menu
            return
            ;;
        *)
            echo -e "${RED}无效的选择！${NC}"
            read -p "按回车键继续..."
            project_management_menu
            return
            ;;
        esac
    fi

    # 检查目录是否已存在
    if [[ -d "$project_path" ]]; then
        echo -e "${YELLOW}目录已存在: $project_path${NC}"
        read -p "是否要重新初始化Git配置？(y/n): " reinit_git
        if [[ $reinit_git == "y" ]]; then
            # 检查是否为Git仓库
            if [[ -d "$project_path/.git" ]]; then
                echo -e "${YELLOW}更新Git配置...${NC}"
                # configure_git_repository "$project_path" "$account_name" "$repo_url" "$github_username" "$github_email"
            else
                echo -e "${YELLOW}初始化Git仓库...${NC}"
                (cd "$project_path" && git init)
                # configure_git_repository "$project_path" "$account_name" "$repo_url" "$github_username" "$github_email"
            fi
        fi
    else
        mkdir -p "$project_path"
    fi

    # 保存项目配置
    echo "$project_alias;$project_name;$account_name;$repo_url;$project_path" >>"$PROJECT_CONFIG"

    echo -e "\n${GREEN}项目配置已添加！${NC}"
    echo "项目路径: $project_path"

    if [[ ! -d "$project_path/.git" ]]; then
        echo -e "\n${YELLOW}克隆选项：${NC}"
        echo "1) 克隆默认分支"
        echo "2) 克隆指定分支"
        echo "3) 不克隆仓库"
        read -p "请选择 [1-3]: " clone_option

        case $clone_option in
        1 | 2)
            branch=""
            if [[ $clone_option == "2" ]]; then
                read -p "请输入要克隆的分支名称: " branch
            fi

            # 如果目录不为空，提供选项
            if [[ "$(ls -A $project_path)" ]]; then
                echo -e "${YELLOW}目标目录不为空，请选择操作：${NC}"
                echo "1) 清空目录并重新克隆"
                echo "2) 初始化现有目录"
                echo "3) 取消操作"
                read -p "请选择 [1-3]: " dir_choice

                case $dir_choice in
                1)
                    rm -rf "$project_path"/*
                    if [[ -n "$branch" ]]; then
                        git clone -b "$branch" "$repo_url" "$project_path"
                    else
                        git clone "$repo_url" "$project_path"
                    fi
                    ;;
                2)
                    (cd "$project_path" && {
                        git init
                        git remote add origin "$repo_url"
                        if [[ -n "$branch" ]]; then
                            git fetch origin "$branch"
                            git checkout -b "$branch" "origin/$branch"
                        fi
                    })
                    ;;
                3)
                    echo -e "${YELLOW}操作已取消${NC}"
                    ;;
                *)
                    echo -e "${RED}无效选择${NC}"
                    ;;
                esac
            else
                if [[ -n "$branch" ]]; then
                    git clone -b "$branch" "$repo_url" "$project_path"
                else
                    git clone "$repo_url" "$project_path"
                fi
            fi
            ;;
        3)
            echo -e "${YELLOW}跳过克隆操作${NC}"
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
        esac
    fi

    # 设置Git配置
    configure_git_repository "$project_path" "$account_name" "$repo_url" "$github_username" "$github_email"

    read -p "按回车键继续..."
    project_management_menu
}

# 优化后的Git仓库配置函数
configure_git_repository() {
    local project_path="$1"
    local account_name="$2"
    local repo_url="$3"
    local github_username="$4"
    local github_email="$5"

    echo -e "\n${YELLOW}正在配置Git仓库...${NC}"

    # 确保目录存在
    if [[ ! -d "$project_path" ]]; then
        mkdir -p "$project_path"
    fi

    # 检查是否已经是Git仓库
    if [[ ! -d "$project_path/.git" ]]; then
        echo -e "${YELLOW}初始化Git仓库...${NC}"
        (cd "$project_path" && git init)
    fi

    # 配置本地Git设置
    (cd "$project_path" && {
        # 基础配置
        git config user.name "$github_username"
        git config user.email "$github_email"

        # SSH配置
        git config core.sshCommand "ssh -i ~/.ssh/id_rsa_$account_name"

        # 配置远程仓库
        if git remote | grep -q "^origin$"; then
            git remote set-url origin "$repo_url"
        else
            git remote add origin "$repo_url"
        fi

        # Git行为优化配置
        git config init.defaultBranch main
        git config pull.rebase false
        git config push.default current
        git config push.autoSetupRemote true

        # 性能优化配置
        git config core.compression 9
        git config core.preloadIndex true
        git config core.fscache true
        git config gc.auto 256

        # 配置差异和合并工具
        git config merge.tool vimdiff
        git config merge.conflictstyle diff3
        git config diff.colorMoved default

        # 配置日志显示格式
        git config log.date iso
        git config format.pretty "%h %ad | %s [%an]"

        # 配置别名
        git config alias.st status
        git config alias.co checkout
        git config alias.br branch
        git config alias.ci commit
        git config alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

        # 如果是空仓库，创建初始提交
        if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
            echo "# $(basename "$project_path")" >README.md
            echo -e "\n## Description\nProject managed by GitHub Account Manager\n" >>README.md
            echo -e "\n## Setup\n\`\`\`bash\n# Clone the repository\ngit clone $repo_url\n\`\`\`" >>README.md
            git add README.md
            git commit -m "chore: Initial commit"
        fi
    })

    # 创建或更新Git hooks
    create_git_hooks "$project_path" "$account_name" "$github_username" "$github_email"

    # 测试SSH连接
    echo -e "\n${YELLOW}测试SSH连接...${NC}"
    if ssh -T -i ~/.ssh/id_rsa_$account_name git@github.com 2>&1 | grep -q "success"; then
        echo -e "${GREEN}SSH连接测试成功！${NC}"
    else
        echo -e "${RED}SSH连接测试失败！${NC}"
        echo -e "请检查以下内容："
        echo -e "1. SSH密钥是否已生成 (~/.ssh/id_rsa_$account_name)"
        echo -e "2. SSH密钥是否已添加到GitHub账号"
        echo -e "3. SSH密钥权限是否正确 (600)"
        echo -e "4. 网络连接是否正常"
    fi

    # 输出配置信息
    echo -e "\n${GREEN}Git仓库配置完成！${NC}"
    echo -e "${BLUE}配置信息：${NC}"
    echo -e "• 项目路径: $project_path"
    echo -e "• SSH地址: $repo_url"
    echo -e "• 用户名: $github_username"
    echo -e "• 邮箱: $github_email"
    echo -e "• SSH密钥: ~/.ssh/id_rsa_$account_name"

    # 更新输出提示，添加分支相关信息
    echo -e "\n${YELLOW}使用提示：${NC}"
    echo -e "1. 确保已将SSH公钥添加到GitHub："
    echo -e "   cat ~/.ssh/id_rsa_${account_name}.pub"
    echo -e "   复制上述内容到 GitHub -> Settings -> SSH Keys"
    echo -e "\n2. 分支操作："
    echo -e "   git branch -a     (查看所有分支)"
    echo -e "   git checkout -b branch_name  (创建并切换分支)"
    echo -e "   git fetch origin  (获取远程分支信息)"
    echo -e "   git checkout -b local_branch origin/remote_branch  (检出远程分支)"
    echo -e "\n3. 推送代码："
    echo -e "   git push -u origin <branch_name>  (首次推送到指定分支)"
    echo -e "   git push         (后续推送)"
    echo -e "\n4. 常用操作："
    echo -e "   git st    (查看状态)"
    echo -e "   git add   (暂存更改)"
    echo -e "   git ci    (提交更改)"
    echo -e "   git pull  (拉取更改)"
    echo -e "   git lg    (查看提交历史)"
}

# 创建 Git hooks
create_git_hooks() {
    local project_path="$1"
    local account_name="$2"
    local github_username="$3"
    local github_email="$4"

    # 创建 hooks 目录
    local hooks_path="$project_path/.git/hooks"
    mkdir -p "$hooks_path"

    # 设置 core.hooksPath
    (cd "$project_path" && git config core.hooksPath "$hooks_path")

    # 创建 pre-push hook
    cat >"$hooks_path/pre-push" <<'EOF'
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}开始检查敏感信息...${NC}"

# 获取要推送的提交范围
while read local_ref local_sha remote_ref remote_sha; do
    # 跳过删除分支的操作
    if [ "$local_sha" = "0000000000000000000000000000000000000000" ]; then
        continue
    fi

    # 确定要检查的提交范围
    if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
        # 新分支，检查所有提交
        range="$local_sha"
    else
        # 已有分支，只检查新的提交
        range="$remote_sha..$local_sha"
    fi

    # 定义敏感信息模式
    patterns=(
        'password\s*=\s*['"'"'"]\S+['"'"'"]'
        'passwd\s*=\s*['"'"'"]\S+['"'"'"]'
        'pwd\s*=\s*['"'"'"]\S+['"'"'"]'
        'secret\s*=\s*['"'"'"]\S+['"'"'"]'
        'token\s*=\s*['"'"'"]\S+['"'"'"]'
        'api[_-]key\s*=\s*['"'"'"]\S+['"'"'"]'
        'access[_-]key\s*=\s*['"'"'"]\S+['"'"'"]'
        'credentials\s*=\s*['"'"'"]\S+['"'"'"]'
    )

    # 组合所有模式为一个正则表达式
    combined_pattern=$(IFS="|"; echo "${patterns[*]}")

    # 检查每个提交中的更改
    found_sensitive=false
    while read -r file; do
        if git diff "$range" -- "$file" | grep -iE "$combined_pattern" >/dev/null; then
            if [ "$found_sensitive" = false ]; then
                echo -e "\n${RED}发现潜在的敏感信息：${NC}"
                found_sensitive=true
            fi
            echo -e "${YELLOW}文件：${NC}$file"
            echo -e "${RED}包含以下敏感信息：${NC}"
            git diff "$range" -- "$file" | grep -iE "$combined_pattern" | sed 's/^/  /'
        fi
    done < <(git diff --name-only "$range")

    if [ "$found_sensitive" = true ]; then
        echo -e "\n${RED}警告：检测到潜在的敏感信息！${NC}"
        echo -e "建议：\n1. 检查并移除敏感信息\n2. 使用环境变量或配置文件存储敏感信息\n3. 确认信息安全后使用 --no-verify 标志强制推送\n4. 使用 git reset HEAD~1 回退到上一个提交"
        exit 1
    fi
done

echo -e "${GREEN}未发现敏感信息，继续推送...${NC}"
exit 0
EOF

    # 创建 pre-commit hook
    cat >"$hooks_path/pre-commit" <<'EOF'
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}执行预提交检查...${NC}"

# 获取暂存的文件列表
staged_files=$(git diff --cached --name-only)

if [ -z "$staged_files" ]; then
    echo -e "${YELLOW}没有暂存的文件需要检查${NC}"
    exit 0
fi

# 检查空白错误
if git diff --check --cached | grep -E '^ +\+.*trailing whitespace|^ +\+.*space before tab|^ +\+.*tab in indent'; then
    echo -e "\n${RED}错误：发现空白字符问题${NC}"
    echo "请修复上述问题后重新提交"
    exit 1
fi

# 检查大文件
max_size_kb=500
error_found=false

while read -r file; do
    # 跳过已删除的文件
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # 获取文件大小（以字节为单位）
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    if [ -n "$size" ] && [ "$size" -gt $((max_size_kb * 1024)) ]; then
        if [ "$error_found" = false ]; then
            echo -e "\n${RED}错误：发现过大的文件：${NC}"
            error_found=true
        fi
        echo -e "${YELLOW}文件：${NC}$file"
        echo -e "${YELLOW}大小：${NC}$((size / 1024))KB (超过${max_size_kb}KB限制)"
    fi
done <<< "$staged_files"

if [ "$error_found" = true ]; then
    exit 1
fi

# 检查文件命名规范
invalid_files=false

while read -r file; do
    # 获取基本文件名（不含路径）
    filename=$(basename "$file")
    
    # 跳过 .git 目录
    if [[ "$file" == .git/* ]]; then
        continue
    fi
    
    # 跳过隐藏文件
    if [[ "$filename" == .* && "$filename" != *..* ]]; then
        continue
    fi
    
    # 检查文件名是否符合规范
    if [[ ! "$filename" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]$ && ! "$filename" =~ ^[a-zA-Z0-9]$ ]]; then
        # 特殊情况处理：常见标准文件
        if [[ ! "$filename" =~ ^(README|CHANGELOG|LICENSE|Dockerfile|Makefile|package|composer)(\.[a-zA-Z0-9]+)?$ ]]; then
            if [ "$invalid_files" = false ]; then
                echo -e "\n${RED}以下文件名可能不符合规范：${NC}"
                invalid_files=true
            fi
            echo -e "• ${YELLOW}$file${NC}"
        fi
    fi
done <<< "$staged_files"

if [ "$invalid_files" = true ]; then
    echo -e "\n${YELLOW}文件命名建议：${NC}"
    echo "• 建议以字母或数字开头和结尾"
    echo "• 可以包含字母、数字、下划线、连字符和点"
    echo "• 避免使用空格和特殊字符"
    echo -e "\n${YELLOW}是否继续提交？(y/n)${NC}"
    read -r response
    if [[ "$response" != "y" ]]; then
        echo -e "${RED}提交已取消${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}预提交检查通过${NC}"
exit 0
EOF

    # 设置执行权限
    chmod +x "$hooks_path/pre-push"
    chmod +x "$hooks_path/pre-commit"

    # 验证 hooks 配置
    local configured_path=$(cd "$project_path" && git config --get core.hooksPath)
    if [[ "$configured_path" == "$hooks_path" ]]; then
        echo -e "${GREEN}Git hooks 已创建并配置成功${NC}"
        echo -e "Hooks 路径: $hooks_path"
    else
        echo -e "${YELLOW}警告: Git hooks 路径配置可能未生效${NC}"
        echo -e "预期路径: $hooks_path"
        echo -e "当前路径: $configured_path"
    fi
}

# 查看项目列表
list_projects() {
    show_banner
    echo -e "${YELLOW}项目列表${NC}"
    echo -e "${BLUE}------------------------${NC}"

    if [[ ! -s "$PROJECT_CONFIG" ]]; then
        echo -e "${RED}暂无配置的项目${NC}"
        read -p "按回车键继续..."
        project_management_menu
        return
    fi

    # 使用普通数组
    declare account_usernames=()
    declare account_emails=()
    declare account_names=()

    # 读取账号信息到数组
    while IFS=';' read -r name username email; do
        account_names+=("$name")
        account_usernames+=("$username")
        account_emails+=("$email")
    done <"$CONFIG_FILE"

    # 一次性读取并格式化输出项目信息
    while IFS=';' read -r alias project_name account_name repo_url project_path; do
        # 查找账号索引
        for i in "${!account_names[@]}"; do
            if [[ "${account_names[$i]}" == "$account_name" ]]; then
                github_username="${account_usernames[$i]}"
                github_email="${account_emails[$i]}"
                break
            fi
        done

        # 清理项目路径
        clean_path=$(echo "$project_path" | sed 's/^[^:]*://')

        echo -e "\n${GREEN}▶ 别名:${NC} ${BLUE}$alias${NC}"
        echo -e "${GREEN}▶ 项目名称:${NC} ${YELLOW}$project_name${NC}"
        echo -e "${GREEN}▶ 关联账号:${NC} ${BLUE}$account_name${NC}"
        echo -e "${GREEN}▶ SSH地址:${NC} $repo_url"
        echo -e "${GREEN}▶ 本地路径:${NC} $clean_path"
        echo -e "${BLUE}------------------------${NC}"
    done <"$PROJECT_CONFIG"

    read -p "按回车键继续..."
    project_management_menu
}

# 删除项目配置
delete_project() {
    show_banner
    echo -e "${YELLOW}删除项目配置${NC}"
    echo "------------------------"

    if [[ ! -s "$PROJECT_CONFIG" ]]; then
        echo -e "${RED}暂无配置的项目${NC}"
        read -p "按回车键继续..."
        project_management_menu
        return
    fi

    echo -e "1) ${YELLOW}通过列表选择${NC}"
    echo -e "2) ${YELLOW}通过别名删除${NC}"
    read -p "请选择删除方式 [1-2]: " delete_method

    case $delete_method in
    1)
        echo -e "\n可删除的项目："
        declare -a aliases=()
        while IFS=';' read -r alias project_name account_name repo_url project_path; do
            aliases+=("$alias")
            echo "$((${#aliases[@]})) [$alias] $project_name ($account_name) - $project_path"
        done <"$PROJECT_CONFIG"

        read -p "选择要删除的项目编号: " project_number

        if [[ $project_number -le ${#aliases[@]} && $project_number -gt 0 ]]; then
            selected_alias=${aliases[$((project_number - 1))]}
            perform_project_deletion "$selected_alias"
        else
            echo -e "${RED}无效的选择${NC}"
        fi
        ;;
    2)
        read -p "输入要删除的项目别名: " input_alias
        if grep -q "^$input_alias;" "$PROJECT_CONFIG"; then
            perform_project_deletion "$input_alias"
        else
            echo -e "${RED}未找到别名为 '$input_alias' 的项目${NC}"
        fi
        ;;
    *)
        echo -e "${RED}无效的选择${NC}"
        ;;
    esac

    read -p "按回车键继续..."
    project_management_menu
}

# 修改执行项目删除的辅助函数
perform_project_deletion() {
    local alias="$1"
    local path="$2"

    # 从配置文件中获取项目信息
    local project_info
    project_info=$(grep "^$alias;" "$PROJECT_CONFIG")

    if [[ -z "$project_info" ]]; then
        echo -e "${RED}无法获取项目信息！${NC}"
        return 1
    fi

    # 解析项目信息
    IFS=';' read -r _ project_name account_name repo_url project_path <<<"$project_info"

    echo -e "\n${BLUE}项目信息：${NC}"
    echo -e "别名: $alias"
    echo -e "名称: $project_name"
    echo -e "账号: $account_name"
    echo -e "路径: $project_path"

    # 确认删除配置
    read -p "确认删除此项目配置? (y/n): " confirm_delete
    if [[ $confirm_delete == "y" ]]; then
        # 删除项目配置
        sed -i '' "/^$alias;/d" "$PROJECT_CONFIG"
        echo -e "${GREEN}项目配置已删除${NC}"

        # 检查并询问是否删除本地文件夹
        if [[ -d "$project_path" ]]; then
            echo -e "\n${YELLOW}是否同时删除本地文件夹?${NC}"
            echo -e "路径: $project_path"
            read -p "删除本地文件夹? (y/n): " delete_folder

            if [[ $delete_folder == "y" ]]; then
                # 再次确认，因为这是危险操作
                echo -e "${RED}警告: 此操作将永久删除文件夹及其所有内容!${NC}"
                read -p "再次确认删除文件夹? (y/n): " confirm_folder_delete

                if [[ $confirm_folder_delete == "y" ]]; then
                    rm -rf "$project_path"
                    echo -e "${GREEN}本地文件夹已删除${NC}"
                else
                    echo -e "${YELLOW}已保留本地文件夹${NC}"
                fi
            else
                echo -e "${YELLOW}已保留本地文件夹${NC}"
            fi
        else
            echo -e "${RED}本地文件夹不存在: $project_path${NC}"
        fi
    else
        echo -e "${YELLOW}操作已取消${NC}"
    fi
}

# 修改查看项目Git信息功能
view_project_git_info() {
    show_banner
    echo -e "${YELLOW}查看项目Git信息${NC}"
    echo "------------------------"

    # 选择项目或输入路径
    echo -e "1) ${YELLOW}从已配置项目中选择${NC}"
    echo -e "2) ${YELLOW}输入项目路径${NC}"
    read -p "请选择操作 [1-2]: " choice

    local project_path=""

    case $choice in
    1)
        if [[ ! -s "$PROJECT_CONFIG" ]]; then
            echo -e "${RED}暂无配置的项目${NC}"
            read -p "按回车键继续..."
            project_management_menu
            return
        fi

        echo -e "\n选择项目："
        declare -a projects=()
        declare -a project_paths=()
        while IFS=';' read -r alias project_name account_name repo_url project_path; do
            projects+=("$project_name")
            project_paths+=("$project_path")
            echo "$((${#projects[@]})) $project_name ($account_name)"
        done <"$PROJECT_CONFIG"

        read -p "选择项目编号: " project_number

        if [[ $project_number -le ${#projects[@]} && $project_number -gt 0 ]]; then
            project_path="${project_paths[$((project_number - 1))]}"

            # 检查项目路径是否存在
            if [[ ! -d "$project_path" ]]; then
                echo -e "${RED}项目目录不存在: $project_path${NC}"
                echo -e "${YELLOW}是否创建目录? (y/n)${NC}"
                read -p "> " create_dir
                if [[ $create_dir == "y" ]]; then
                    mkdir -p "$project_path"
                    echo -e "${GREEN}目录已创建${NC}"
                else
                    read -p "按回车键继续..."
                    project_management_menu
                    return
                fi
            fi
        else
            echo -e "${RED}无效的选择${NC}"
            read -p "按回车键继续..."
            project_management_menu
            return
        fi
        ;;
    2)
        read -p "输入项目完整路径: " project_path
        ;;
    esac

    if [[ -d "$project_path/.git" ]]; then
        echo -e "\n${GREEN}项目Git信息：${NC}"
        echo "------------------------"
        echo -e "项目路径: $project_path"
        echo -e "当前分支: $(cd "$project_path" && git branch --show-current)"
        echo -e "本地配置:"
        echo -e "  用户名: $(cd "$project_path" && git config --local user.name 2>/dev/null || echo '未设置')"
        echo -e "  邮箱: $(cd "$project_path" && git config --local user.email 2>/dev/null || echo '未设置')"
        echo -e "全局配置:"
        echo -e "  用户名: $(git config --global user.name 2>/dev/null || echo '未设置')"
        echo -e "  邮箱: $(git config --global user.email 2>/dev/null || echo '未设置')"
        echo -e "远程仓库: "
        cd "$project_path" && git remote -v || echo '未设置'
        echo -e "SSH命令: $(cd "$project_path" && git config core.sshCommand 2>/dev/null || echo '未设置')"
    else
        echo -e "${RED}指定路径不是Git仓库: $project_path${NC}"
        echo -e "${YELLOW}是否要初始化为Git仓库? (y/n)${NC}"
        read -p "> " init_git
        if [[ $init_git == "y" ]]; then
            (cd "$project_path" && git init)
            echo -e "${GREEN}Git仓库已初始化${NC}"
        fi
    fi

    read -p "按回车键继续..."
    project_management_menu
}

# 新增查看原始配置文件函数
view_raw_config() {
    show_banner
    echo -e "${YELLOW}原始配置文件内容${NC}"
    echo "------------------------"

    echo -e "${GREEN}账号配置文件 ($CONFIG_FILE):${NC}"
    echo "------------------------"
    if [[ -s "$CONFIG_FILE" ]]; then
        cat "$CONFIG_FILE"
    else
        echo "文件为空"
    fi

    echo -e "\n${GREEN}项目配置文件 ($PROJECT_CONFIG):${NC}"
    echo "------------------------"
    if [[ -s "$PROJECT_CONFIG" ]]; then
        cat "$PROJECT_CONFIG"
    else
        echo "文件为空"
    fi

    echo -e "\n${GREEN}SSH配置文件 ($SSH_CONFIG):${NC}"
    echo "------------------------"
    if [[ -s "$SSH_CONFIG" ]]; then
        cat "$SSH_CONFIG"
    else
        echo "文件为空"
    fi

    read -p "按回车键返回主菜单..."
    show_main_menu
}

# 新增：配置当前目录的Git设置
configure_current_directory() {
    show_banner
    echo -e "${YELLOW}配置当前目录Git设置${NC}"
    echo "------------------------"

    # 获取当前目录
    current_path=$(pwd)
    echo -e "当前路径: ${GREEN}$current_path${NC}"

    # 检查是否已在项目配置中
    current_path_alias=""
    while IFS=';' read -r alias p_name p_account p_repo p_path; do
        # 清理路径中的冒号
        clean_path=$(echo "$p_path" | sed 's/^[^:]*://')
        if [[ "$clean_path" == "$current_path" ]]; then
            current_path_alias="$alias"
            echo -e "${YELLOW}注意：该目录已在项目管理中${NC}"
            echo -e "\n${GREEN}当前配置信息:${NC}"
            echo -e "┌──────────────────────────────────────────"
            echo -e "│ ${YELLOW}别名:${NC}     $alias"
            echo -e "│ ${YELLOW}项目名称:${NC} $p_name"
            echo -e "│ ${YELLOW}关联账号:${NC} $p_account"
            echo -e "│ ${YELLOW}仓库地址:${NC} $p_repo"
            echo -e "│ ${YELLOW}本地路径:${NC} $clean_path"
            echo -e "└──────────────────────────────────────────"
            break
        fi
    done <"$PROJECT_CONFIG"

    # 检查是否是Git仓库
    if [[ ! -d "$current_path/.git" ]]; then
        echo -e "${RED}当前目录不是Git仓库${NC}"
        echo -e "是否要初始化为Git仓库? (y/n)"
        read -p "> " init_git
        if [[ $init_git == "y" ]]; then
            git init
            echo -e "${GREEN}Git仓库已初始化${NC}"
        else
            read -p "按回车键返回主菜单..."
            show_main_menu
            return
        fi
    fi

    # 显示当前Git配置
    echo -e "\n${BLUE}当前Git配置：${NC}"
    echo -e "┌──────────────────────────────────────────"
    echo -e "│ ${YELLOW}用户名:${NC}    $(git config --local user.name 2>/dev/null || echo '未设置')"
    echo -e "│ ${YELLOW}邮箱:${NC}      $(git config --local user.email 2>/dev/null || echo '未设置')"
    echo -e "│ ${YELLOW}SSH命令:${NC}   $(git config --local core.sshCommand 2>/dev/null || echo '未设置')"
    echo -e "│ ${YELLOW}远程仓库${NC}"
    echo -e "$(git remote -v 2>/dev/null | sed 's/^/│ /' || echo '│ 未设置')"
    echo -e "└──────────────────────────────────────────"

    # 显示可用账号
    if [[ ! -s "$CONFIG_FILE" ]]; then
        echo -e "\n${RED}暂无配置的账号，请先添加账号！${NC}"
        read -p "按回车键返回主菜单..."
        show_main_menu
        return
    fi

    echo -e "\n${YELLOW}选择要使用的账号：${NC}"
    declare -a accounts=()
    declare -a usernames=()
    declare -a emails=()
    while IFS=';' read -r account_name github_username github_email; do
        accounts+=("$account_name")
        usernames+=("$github_username")
        emails+=("$github_email")
        echo "$((${#accounts[@]})) $account_name ($github_username)"
    done <"$CONFIG_FILE"
    echo -e "0 ${RED}返回主菜单${NC}"

    read -p "选择账号编号 [0-${#accounts[@]}]: " account_number

    if [[ $account_number == "0" ]]; then
        show_main_menu
        return
    elif [[ $account_number -le ${#accounts[@]} && $account_number -gt 0 ]]; then
        index=$((account_number - 1))
        account_name="${accounts[$index]}"
        github_username="${usernames[$index]}"
        github_email="${emails[$index]}"

        # 设置Git配置
        git config --local user.name "$github_username"
        git config --local user.email "$github_email"
        git config --local core.sshCommand "ssh -i ~/.ssh/id_rsa_$account_name"

        # 询问是否配置远程仓库
        echo -e "\n${YELLOW}是否配置远程仓库? (y/n)${NC}"
        read -p "> " config_remote
        repo_url=""
        repo_name=""
        if [[ $config_remote == "y" ]]; then
            # 获取当前目录名作为默认仓库名
            default_repo=$(basename "$current_path")
            read -p "输入仓库名 [$default_repo]: " repo_name
            repo_name=${repo_name:-$default_repo}

            # 构建SSH地址
            repo_url="git@github.com:$github_username/$repo_name.git"

            # 配置远程仓库
            if git remote | grep -q "^origin$"; then
                echo -e "${YELLOW}远程仓库 'origin' 已存在，是否更新? (y/n)${NC}"
                read -p "> " update_remote
                if [[ $update_remote == "y" ]]; then
                    git remote set-url origin "$repo_url"
                    echo -e "${GREEN}远程仓库地址已更新${NC}"
                fi
            else
                git remote add origin "$repo_url"
                echo -e "${GREEN}远程仓库已添加${NC}"
            fi
        else
            # 如果没有配置远程仓库，使用当前目录名作为项目名
            repo_name=$(basename "$current_path")
            # 尝试从现有git配置获取远程仓库地址
            repo_url=$(git config --get remote.origin.url || echo "")
        fi

        # 创建Git hooks
        create_git_hooks "$current_path" "$account_name" "$github_username" "$github_email"

        echo -e "\n${GREEN}Git配置已更新：${NC}"
        echo -e "用户名: $github_username"
        echo -e "邮箱: $github_email"
        echo -e "SSH命令: ssh -i ~/.ssh/id_rsa_$account_name"

        # 询问是否添加到项目管理
        echo -e "\n${YELLOW}是否将此项目添加到项目管理? (y/n)${NC}"
        read -p "> " add_to_projects
        if [[ $add_to_projects == "y" ]]; then
            # 生成随机别名（基于项目名和时间戳）
            generate_alias() {
                local base_name="$1"
                local timestamp=$(date +%s)
                local random_num=$RANDOM
                local hash_base="${timestamp}${random_num}${current_path}"
                local path_hash=$(echo "$hash_base" | cksum | cut -d' ' -f1)
                local alias="${base_name:0:3}${path_hash:0:3}"
                while grep -q "^$alias;" "$PROJECT_CONFIG"; do
                    random_num=$RANDOM
                    path_hash=$(echo "${hash_base}${random_num}" | cksum | cut -d' ' -f1)
                    alias="${base_name:0:3}${path_hash:0:3}"
                done
                echo "$alias"
            }

            # 使用之前已经检查过的 current_path_alias
            if [[ -n "$current_path_alias" ]]; then
                echo -e "${YELLOW}项目路径已存在，是否更新配置? (y/n)${NC}"
                read -p "> " update_project
                if [[ $update_project == "y" ]]; then
                    # 使用临时文件进行安全的文件更新
                    temp_file=$(mktemp)

                    # 读取每一行并进行精确匹配和替换
                    while IFS=';' read -r old_alias old_name old_account old_repo old_path || [[ -n "$old_path" ]]; do
                        if [[ "$old_path" == "$current_path" ]]; then
                            # 跳过当前行（相当于删除）
                            continue
                        fi
                        # 保留其他行
                        echo "$old_alias;$old_name;$old_account;$old_repo;$old_path" >>"$temp_file"
                    done <"$PROJECT_CONFIG"

                    # 添加更新后的配置
                    echo "$current_path_alias;$repo_name;$account_name;$repo_url;$current_path" >>"$temp_file"

                    # 安全地替换原文件
                    mv "$temp_file" "$PROJECT_CONFIG"

                    echo -e "${GREEN}项目配置已更新${NC}"
                    echo -e "项目别名: ${BLUE}$current_path_alias${NC}"
                    echo -e "项目名称: ${BLUE}$repo_name${NC}"
                    echo -e "仓库地址: ${BLUE}$repo_url${NC}"
                fi
            else
                # 生成新的别名
                new_alias=$(generate_alias "$repo_name")
                # 添加新项目配置
                echo "$new_alias;$repo_name;$account_name;$repo_url;$current_path" >>"$PROJECT_CONFIG"
                echo -e "${GREEN}项目已添加到项目管理${NC}"
                echo -e "项目别名: ${BLUE}$new_alias${NC}"
                echo -e "项目名称: ${BLUE}$repo_name${NC}"
                echo -e "仓库地址: ${BLUE}$repo_url${NC}"
            fi
        fi
    else
        echo -e "${RED}无效的选择${NC}"
    fi

    read -p "按回车键返回主菜单..."
    show_main_menu
}

# 新增：项目操作菜单
project_operations_menu() {
    show_banner
    echo -e "\n${BLUE}┌─────────── 项目操作 ───────────┐${NC}"

    # 检查是否有配置的项目
    if [[ ! -s "$PROJECT_CONFIG" ]]; then
        echo -e "│ ${RED}✗ 暂无配置的项目${NC}"
        echo -e "└────────────────────────────────┘"
        read -p "按回车键返回主菜单..."
        show_main_menu
        return
    fi

    # 显示项目列表
    echo -e "│ ${GREEN}可操作的项目列表:${NC}"
    echo -e "│"
    declare -a projects=()
    declare -a project_paths=()
    declare -a project_accounts=()

    while IFS=';' read -r alias project_name account_name repo_url project_path; do
        projects+=("$project_name")
        project_paths+=("$project_path")
        project_accounts+=("$account_name")
        echo -e "│ ${YELLOW}$((${#projects[@]}))${NC}) [${BLUE}$alias${NC}] ${GREEN}$project_name${NC}"
        echo -e "│   ${YELLOW}账号:${NC} $account_name"
        echo -e "│   ${YELLOW}路径:${NC} $project_path"
        echo -e "│"
    done <"$PROJECT_CONFIG"

    echo -e "│ ${RED}0)${NC} 返回主菜单"
    echo -e "└────────────────────────────────┘"

    read -p "请选择项目编号 [0-${#projects[@]}]: " project_choice

    if [[ $project_choice == "0" ]]; then
        show_main_menu
        return
    elif [[ $project_choice -le ${#projects[@]} && $project_choice -gt 0 ]]; then
        selected_path="${project_paths[$((project_choice - 1))]}"
        selected_project="${projects[$((project_choice - 1))]}"
        selected_account="${project_accounts[$((project_choice - 1))]}"

        show_project_operations "$selected_path" "$selected_project" "$selected_account"
    else
        echo -e "\n${RED}┌─────────── 错误提示 ───────────┐${NC}"
        echo -e "│ ✗ 无效的选择，请重新输入"
        echo -e "└────────────────────────────────┘"
        read -p "按回车键继续..."
        project_operations_menu
    fi
}

# 新增：显示项目操作选项
show_project_operations() {
    local project_path="$1"
    local project_name="$2"
    local account_name="$3"

    while true; do
        show_banner
        echo -e "${YELLOW}项目：${NC}$project_name"
        echo -e "${YELLOW}路径：${NC}$project_path"
        echo -e "${YELLOW}账号：${NC}$account_name"
        echo "------------------------"

        # 检查目录是否存在
        if [[ ! -d "$project_path" ]]; then
            echo -e "${RED}错误：项目目录不存在！${NC}"
            read -p "按回车键返回..."
            project_operations_menu
            return
        fi

        # 获取当前分支
        current_branch=$(cd "$project_path" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "未初始化")
        echo -e "${GREEN}当前分支：${NC}$current_branch"
        echo -e "------------------------"

        echo -e "1) ${YELLOW}拉取更新${NC}"
        echo -e "2) ${YELLOW}推送更改${NC}"
        echo -e "3) ${YELLOW}查看状态${NC}"
        echo -e "4) ${YELLOW}分支管理${NC}"
        echo -e "5) ${YELLOW}提交更改并推送 🌟 ${NC}"
        echo -e "6) ${YELLOW}查看日志${NC}"
        echo -e "7) ${YELLOW}同步远程分支${NC}"
        echo -e "8) ${YELLOW}打开项目目录${NC}"
        echo -e "9) ${YELLOW}提交管理${NC}"
        echo -e "10) ${YELLOW}返回项目列表${NC}"
        echo -e "0) ${RED}返回主菜单${NC}"

        read -p "请选择操作 [0-10]: " op_choice

        case $op_choice in
        1) git_pull "$project_path" ;;
        2) git_push "$project_path" ;;
        3) git_status "$project_path" ;;
        4) branch_management "$project_path" ;;
        5) commit_changes "$project_path" ;;
        6) view_logs "$project_path" ;;
        7) sync_remote_branches "$project_path" ;;
        8) open_project_directory "$project_path" ;;
        9) manage_recent_commits "$project_path" ;; # 新增选项处理
        10)
            project_operations_menu
            return
            ;;
        0)
            show_main_menu
            return
            ;;
        *) echo -e "${RED}无效选择${NC}" && sleep 2 ;;
        esac
    done
}

# 新增：Git操作相关函数
git_pull() {
    local project_path="$1"
    echo -e "\n${BLUE}┌─────────── 拉取更新 ───────────┐${NC}"
    (cd "$project_path" && {
        # 获取当前分支信息
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

        echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
        if [[ -n "$remote_branch" ]]; then
            echo -e "│ ${YELLOW}远程分支:${NC} $remote_branch"
        else
            echo -e "│ ${RED}警告: 未设置远程跟踪分支${NC}"
            echo -e "└────────────────────────────────┘"
            read -p "是否设置远程跟踪分支？(y/n): " set_upstream
            if [[ $set_upstream == "y" ]]; then
                echo -e "\n${YELLOW}可用的远程分支:${NC}"
                git branch -r
                read -p "输入要跟踪的远程分支(例如 origin/main): " track_branch
                if git branch --set-upstream-to="$track_branch" "$current_branch"; then
                    echo -e "${GREEN}✓ 已设置跟踪分支${NC}"
                    remote_branch="$track_branch"
                else
                    echo -e "${RED}✗ 设置跟踪分支失败${NC}"
                    read -p "按回车键继续..."
                    return 1
                fi
            else
                read -p "按回车键继续..."
                return 1
            fi
        fi
        echo -e "├────────────────────────────────┤"

        # 检查本地更改
        if [[ -n "$(git status --porcelain)" ]]; then
            echo -e "│ ${YELLOW}检测到本地未提交的更改:${NC}"
            git status -s | while IFS= read -r line; do
                status=${line:0:2}
                file=${line:3}
                case $status in
                "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
                " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
                "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
                "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
                "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
                *) echo -e "│ $line" ;;
                esac
            done
            echo -e "├────────────────────────────────┤"
        fi

        # 执行 fetch 并显示更新信息
        echo -e "│ ${YELLOW}正在获取远程更新...${NC}"
        git fetch --all --prune

        # 检查是否有更新
        local_commit=$(git rev-parse HEAD)
        remote_commit=$(git rev-parse "$remote_branch")

        if [[ "$local_commit" == "$remote_commit" ]]; then
            echo -e "│ ${GREEN}✓ 已是最新版本${NC}"
            echo -e "└────────────────────────────────┘"
            read -p "按回车键继续..."
            return 0
        fi

        # 显示更新信息
        echo -e "│ ${YELLOW}远程更新详情:${NC}"
        git --no-pager log --oneline HEAD.."$remote_branch" | while IFS= read -r line; do
            echo -e "│ • $line"
        done
        echo -e "├────────────────────────────────┤"

        # 拉取选项
        echo -e "│ ${YELLOW}拉取选项:${NC}"
        echo -e "│ 1) 正常拉取"
        echo -e "│ 2) 变基拉取 (rebase)"
        echo -e "│ 3) 强制拉取 (hard reset)"
        echo -e "│ 4) 取消操作"
        echo -e "└────────────────────────────────┘"

        read -p "请选择拉取方式 [1-4]: " pull_option

        case $pull_option in
        1)
            if [[ -n "$(git status --porcelain)" ]]; then
                echo -e "${YELLOW}检测到本地更改，是否储藏？(y/n)${NC}"
                read -p "> " do_stash
                if [[ $do_stash == "y" ]]; then
                    git stash save "自动储藏于 $(date '+%Y-%m-%d %H:%M:%S')"
                    echo -e "${GREEN}✓ 更改已储藏${NC}"
                fi
            fi

            if git pull; then
                echo -e "${GREEN}✓ 拉取成功${NC}"
                if [[ $do_stash == "y" ]]; then
                    echo -e "${YELLOW}是否恢复储藏的更改？(y/n)${NC}"
                    read -p "> " do_pop
                    if [[ $do_pop == "y" ]]; then
                        git stash pop
                        echo -e "${GREEN}✓ 储藏的更改已恢复${NC}"
                    fi
                fi
            else
                echo -e "${RED}✗ 拉取失败${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}执行变基拉取...${NC}"
            if git pull --rebase; then
                echo -e "${GREEN}✓ 变基拉取成功${NC}"
            else
                echo -e "${RED}✗ 变基失败${NC}"
                echo -e "${YELLOW}提示: 请解决冲突后继续变基${NC}"
            fi
            ;;
        3)
            echo -e "${RED}警告: 强制拉取将丢失所有本地更改！${NC}"
            read -p "确认继续？(y/n): " confirm_reset
            if [[ $confirm_reset == "y" ]]; then
                if git reset --hard "$remote_branch"; then
                    echo -e "${GREEN}✓ 已强制更新到远程版本${NC}"
                else
                    echo -e "${RED}✗ 强制更新失败${NC}"
                fi
            else
                echo -e "${YELLOW}已取消强制拉取${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}已取消拉取操作${NC}"
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
        esac

        # 显示最终状态
        if [[ $pull_option != "4" ]]; then
            echo -e "\n${BLUE}当前状态:${NC}"
            git status -s

            # 显示最新的提交信息
            echo -e "\n${YELLOW}最新提交:${NC}"
            git --no-pager log -1 --oneline
        fi
    })
    read -p "按回车键继续..."
}

git_push() {
    local project_path="$1"
    echo -e "\n${BLUE}┌─────────── 推送管理 ───────────┐${NC}"
    (cd "$project_path" && {
        # 获取当前分支信息
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

        echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
        if [[ -n "$remote_branch" ]]; then
            echo -e "│ ${YELLOW}远程分支:${NC} $remote_branch"
        else
            echo -e "│ ${RED}警告: 未设置远程跟踪分支${NC}"
        fi
        echo -e "├────────────────────────────────┤"

        # 检查是否有未推送的提交
        unpushed_commits=$(git log @{u}.. --oneline 2>/dev/null)
        if [[ -n "$unpushed_commits" ]]; then
            echo -e "│ ${YELLOW}待推送的提交:${NC}"
            echo "$unpushed_commits" | while IFS= read -r line; do
                echo -e "│ • $line"
            done
            echo -e "├────────────────────────────────┤"
        fi

        # 显示当前状态
        echo -e "│ ${BLUE}当前状态:${NC}"
        git status -s | while IFS= read -r line; do
            status=${line:0:2}
            file=${line:3}
            case $status in
            "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
            " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
            "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
            "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
            "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
            *) echo -e "│ $line" ;;
            esac
        done
        echo -e "├────────────────────────────────┤"

        # 推送选项菜单
        echo -e "│ ${YELLOW}推送选项:${NC}"
        echo -e "│ 1) 正常推送"
        echo -e "│ 2) 强制推送 (--force)"
        echo -e "│ 3) 忽略钩子推送 (--no-verify)"
        echo -e "│ 4) 取消操作"
        echo -e "└────────────────────────────────┘"

        read -p "请选择推送方式 [1-4]: " push_option

        case $push_option in
        1)
            echo -e "\n${YELLOW}正在执行标准推送...${NC}"
            if git push origin "$current_branch"; then
                echo -e "${GREEN}✓ 推送成功${NC}"
            else
                echo -e "${RED}✗ 推送失败${NC}"
                echo -e "\n${YELLOW}是否尝试其他推送方式？(y/n)${NC}"
                read -p "> " retry_push
                if [[ $retry_push == "y" ]]; then
                    continue
                fi
            fi
            ;;
        2)
            echo -e "\n${RED}警告: 强制推送可能会覆盖远程更改！${NC}"
            echo -e "确认要继续吗？(y/n)"
            read -p "> " confirm_force
            if [[ $confirm_force == "y" ]]; then
                if git push --force origin "$current_branch"; then
                    echo -e "${GREEN}✓ 强制推送成功${NC}"
                else
                    echo -e "${RED}✗ 强制推送失败${NC}"
                fi
            else
                echo -e "${YELLOW}已取消强制推送${NC}"
            fi
            ;;
        3)
            echo -e "\n${YELLOW}警告: 将跳过所有 Git 钩子检查${NC}"
            echo -e "确认要继续吗？(y/n)"
            read -p "> " confirm_no_verify
            if [[ $confirm_no_verify == "y" ]]; then
                if git push --no-verify origin "$current_branch"; then
                    echo -e "${GREEN}✓ 推送成功 (已跳过钩子检查)${NC}"
                else
                    echo -e "${RED}✗ 推送失败${NC}"
                fi
            else
                echo -e "${YELLOW}已取消推送${NC}"
            fi
            ;;
        4)
            echo -e "${YELLOW}已取消推送操作${NC}"
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
        esac

        # 推送后状态检查
        if [[ $push_option != "4" ]]; then
            echo -e "\n${BLUE}推送后状态:${NC}"
            # 获取状态并格式化输出
            local status_output=$(git status -s)
            if [[ -n "$status_output" ]]; then
                echo -e "│ ${YELLOW}未提交的更改:${NC}"
                while IFS= read -r line; do
                    local status_code="${line:0:2}"
                    local file_name="${line:3}"
                    case "$status_code" in
                    "M " | "MM") echo -e "│ ${BLUE}已修改:${NC} $file_name" ;;
                    " M") echo -e "│ ${YELLOW}工作区已修改:${NC} $file_name" ;;
                    "A ") echo -e "│ ${GREEN}新增:${NC} $file_name" ;;
                    "D ") echo -e "│ ${RED}删除:${NC} $file_name" ;;
                    "R ") echo -e "│ ${PURPLE}重命名:${NC} $file_name" ;;
                    "??") echo -e "│ ${GRAY}未跟踪:${NC} $file_name" ;;
                    *) echo -e "│ $status_code $file_name" ;;
                    esac
                done <<<"$status_output"
            else
                echo -e "│ ${GREEN}✓ 工作区清洁，没有未提交的更改${NC}"
            fi

            # 检查是否还有未推送的提交
            remaining_commits=$(git log @{u}.. --oneline 2>/dev/null)
            if [[ -n "$remaining_commits" ]]; then
                echo -e "\n${YELLOW}注意: 仍有未推送的提交:${NC}"
                echo "$remaining_commits"
            else
                echo -e "\n${GREEN}✓ 所有提交已同步到远程仓库${NC}"
            fi
        fi
    })
    read -p "按回车键继续..."
}

git_status() {
    local project_path="$1"
    echo -e "\n${YELLOW}Git 仓库状态概览${NC}"
    echo -e "------------------------"

    (cd "$project_path" && {
        # 检查是否是 Git 仓库
        if [[ ! -d ".git" ]]; then
            echo -e "${RED}错误：当前目录不是 Git 仓库${NC}"
            return 1
        fi

        # 获取基本信息
        local current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local current_commit=$(git rev-parse --short HEAD 2>/dev/null)
        local current_remote=$(git config --get branch.$current_branch.remote)
        local repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
        local repo_name=$(basename "$repo_root")
        local last_commit_info=$(git --no-pager log -1 --pretty=format:"%h - %s (%cr) <%an>")
        local last_commit_date=$(git --no-pager log -1 --format=%cd --date=format:"%Y-%m-%d %H:%M:%S")
        local first_commit_date=$(git --no-pager log --reverse --format=%cd --date=format:"%Y-%m-%d %H:%M:%S" | head -1)

        # 显示仓库基本信息
        echo -e "${BLUE}仓库基本信息:${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ ${YELLOW}仓库名称:${NC} $repo_name"
        echo -e "│ ${YELLOW}仓库路径:${NC} $repo_root"
        echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
        echo -e "│ ${YELLOW}最新提交:${NC} $last_commit_info"
        echo -e "│ ${YELLOW}最后更新:${NC} $last_commit_date"
        echo -e "│ ${YELLOW}创建时间:${NC} $first_commit_date"
        echo -e "└──────────────────────────────────────────"

        # 显示分支详细信息
        echo -e "\n${BLUE}分支详细信息:${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ ${YELLOW}本地分支:${NC}"
        git --no-pager branch -vv | sed 's/^/│ /'
        echo -e "│"
        echo -e "│ ${YELLOW}远程分支:${NC}"
        git --no-pager branch -r -vv | sed 's/^/│ /'
        echo -e "└──────────────────────────────────────────"

        # 显示同步状态
        echo -e "\n${BLUE}同步状态:${NC}"
        echo -e "┌──────────────────────────────────────────"
        if [[ -n "$current_remote" ]]; then
            if ahead_behind=$(git rev-list --left-right --count $current_branch...origin/$current_branch 2>/dev/null); then
                read -r ahead behind <<<"$ahead_behind"
                if [ "$ahead" -gt 0 ]; then
                    echo -e "│ ${YELLOW}• 本地领先远程 $ahead 个提交${NC}"
                    # 显示领先的提交
                    echo -e "│ ${YELLOW}领先的提交:${NC}"
                    git --no-pager log --oneline origin/$current_branch..$current_branch | sed 's/^/│   /'
                fi
                if [ "$behind" -gt 0 ]; then
                    echo -e "│ ${RED}• 本地落后远程 $behind 个提交${NC}"
                    # 显示落后的提交
                    echo -e "│ ${RED}落后的提交:${NC}"
                    git --no-pager log --oneline $current_branch..origin/$current_branch | sed 's/^/│   /'
                fi
                if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
                    echo -e "│ ${GREEN}• 与远程分支完全同步${NC}"
                fi
            else
                echo -e "│ ${RED}• 远程分支未配置${NC}"
            fi
        else
            echo -e "│ ${YELLOW}• 未设置远程仓库${NC}"
        fi
        echo -e "└──────────────────────────────────────────"

        # 显示最近活动
        echo -e "\n${BLUE}最近活动:${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ ${YELLOW}最近提交:${NC}"
        git --no-pager log -5 --pretty=format:"│ %C(yellow)%h%Creset - %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset" --abbrev-commit
        echo -e "\n│"
        echo -e "│ ${YELLOW}最近操作:${NC}"
        git --no-pager reflog -5 --pretty=format:"│ %C(yellow)%h%Creset - %s %C(green)(%cr)%Creset" | sed 's/: /│ /'
        echo -e "\n└──────────────────────────────────────────"

        # 显示工作区和暂存区状态
        local status_output=$(git status --porcelain)
        if [[ -n "$status_output" ]]; then
            echo -e "\n${BLUE}文件变更详情:${NC}"
            echo -e "┌──────────────────────────────────────────"
            echo -e "│ ${YELLOW}变更统计:${NC}"

            # 统计变更数量
            local modified_count=$(echo "$status_output" | grep -c "^.M")
            local added_count=$(echo "$status_output" | grep -c "^A")
            local deleted_count=$(echo "$status_output" | grep -c "^.D")
            local renamed_count=$(echo "$status_output" | grep -c "^R")
            local untracked_count=$(echo "$status_output" | grep -c "^??")

            [[ $modified_count -gt 0 ]] && echo -e "│ • 修改: $modified_count 个文件"
            [[ $added_count -gt 0 ]] && echo -e "│ • 新增: $added_count 个文件"
            [[ $deleted_count -gt 0 ]] && echo -e "│ • 删除: $deleted_count 个文件"
            [[ $renamed_count -gt 0 ]] && echo -e "│ • 重命名: $renamed_count 个文件"
            [[ $untracked_count -gt 0 ]] && echo -e "│ • 未跟踪: $untracked_count 个文件"

            # 显示详细变更
            echo -e "│"
            echo -e "│ ${YELLOW}详细变更:${NC}"
            echo "$status_output" | while read -r line; do
                local status=${line:0:2}
                local file=${line:3}
                local status_desc=""
                case $status in
                "M ") status_desc="${GREEN}已暂存修改${NC}" ;;
                " M") status_desc="${RED}未暂存修改${NC}" ;;
                "A ") status_desc="${GREEN}新增${NC}" ;;
                " A") status_desc="${RED}未暂存新增${NC}" ;;
                "D ") status_desc="${GREEN}已暂存删除${NC}" ;;
                " D") status_desc="${RED}未暂存删除${NC}" ;;
                "R ") status_desc="${GREEN}重命名${NC}" ;;
                "??") status_desc="${YELLOW}未跟踪${NC}" ;;
                *) status_desc="未知状态" ;;
                esac
                echo -e "│ • [$status_desc] $file"

                # 显示文件详细信息
                if [[ -f "$file" ]]; then
                    local file_type=$(file -b "$file")
                    local file_size=$(ls -lh "$file" | awk '{print $5}')
                    local file_perms=$(ls -l "$file" | awk '{print $1}')
                    echo -e "│   └─ 类型: $file_type"
                    echo -e "│   └─ 大小: $file_size"
                    echo -e "│   └─ 权限: $file_perms"
                fi
            done
            echo -e "└──────────────────────────────────────────"
        fi

        # 显示储藏详情
        if [[ -n "$(git stash list)" ]]; then
            echo -e "\n${BLUE}储藏详情:${NC}"
            echo -e "┌──────────────────────────────────────────"
            git --no-pager stash list --format="│ %C(yellow)%gd%Creset: %C(green)%cr%Creset - %s" | sed 's/stash@{/储藏 #/'
            echo -e "└──────────────────────────────────────────"
        fi

        # 显示仓库统计
        echo -e "\n${BLUE}仓库统计:${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ ${YELLOW}基础统计:${NC}"
        echo -e "│ • 文件总数: $(git ls-files | wc -l | tr -d ' ')"
        echo -e "│ • 目录总数: $(git ls-files | grep "/" | cut -d/ -f1 | sort -u | wc -l | tr -d ' ')"
        echo -e "│ • 仓库大小: $(du -sh .git 2>/dev/null | cut -f1)"
        echo -e "│ • 工作区大小: $(du -sh . 2>/dev/null | cut -f1)"

        echo -e "│"
        echo -e "│ ${YELLOW}提交统计:${NC}"
        echo -e "│ • 总提交数: $(git --no-pager rev-list --count HEAD)"
        echo -e "│ • 总分支数: $(git --no-pager branch | wc -l | tr -d ' ')"
        echo -e "│ • 贡献者数: $(git --no-pager shortlog -s | wc -l | tr -d ' ')"

        echo -e "│"
        echo -e "│ ${YELLOW}活跃度统计:${NC}"
        echo -e "│ • 最近一周提交: $(git --no-pager log --since="1 week ago" --oneline | wc -l | tr -d ' ')"
        echo -e "│ • 最近一月提交: $(git --no-pager log --since="1 month ago" --oneline | wc -l | tr -d ' ')"

        # 显示主要贡献者
        echo -e "│"
        echo -e "│ ${YELLOW}主要贡献者:${NC}"
        git --no-pager shortlog -sn --no-merges | head -5 | sed 's/^/│ • /'
        echo -e "└──────────────────────────────────────────"

        # 显示配置信息
        echo -e "\n${BLUE}Git 配置信息:${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ ${YELLOW}本地配置:${NC}"
        echo -e "│ • 用户名: $(git config --local user.name 2>/dev/null || echo '未设置')"
        echo -e "│ • 邮箱: $(git config --local user.email 2>/dev/null || echo '未设置')"
        echo -e "│ • SSH命令: $(git config --local core.sshCommand 2>/dev/null || echo '未设置')"
        echo -e "│"
        echo -e "│ ${YELLOW}全局配置:${NC}"
        echo -e "│ • 用户名: $(git config --global user.name 2>/dev/null || echo '未设置')"
        echo -e "│ • 邮箱: $(git config --global user.email 2>/dev/null || echo '未设置')"
        echo -e "└──────────────────────────────────────────"

        # 显示 Hooks 状态
        if [[ -d ".git/hooks" ]]; then
            echo -e "\n${BLUE}Git Hooks 状态:${NC}"
            echo -e "┌──────────────────────────────────────────"
            for hook in pre-commit post-commit pre-push post-push pre-rebase post-rebase; do
                if [[ -x ".git/hooks/$hook" ]]; then
                    echo -e "│ • ${GREEN}$hook${NC} (已启用)"
                else
                    echo -e "│ • ${YELLOW}$hook${NC} (未启用)"
                fi
            done
            echo -e "└──────────────────────────────────────────"
        fi
    })

    read -p "按回车键继续..."
}

branch_management() {
    local project_path="$1"
    while true; do
        echo -e "\n${BLUE}┌─────────── 分支管理 ───────────┐${NC}"

        # 获取当前分支信息
        current_branch=$(cd "$project_path" && git rev-parse --abbrev-ref HEAD)
        echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
        echo -e "├────────────────────────────────┤"

        echo -e "│ ${YELLOW}可用操作:${NC}"
        echo -e "│ 1) 查看分支详情"
        echo -e "│ 2) 创建新分支"
        echo -e "│ 3) 切换分支"
        echo -e "│ 4) 删除分支"
        echo -e "│ 5) 重命名分支"
        echo -e "│ 6) 合并分支"
        echo -e "│ 7) 拉取远程分支"
        echo -e "│ 8) 推送本地分支"
        echo -e "│ 9) 设置上游分支"
        echo -e "│ 0) 返回上级菜单"
        echo -e "└────────────────────────────────┘"

        read -p "请选择操作 [0-9]: " branch_choice

        case $branch_choice in
        1)
            echo -e "\n${BLUE}┌─────────── 分支详情 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}本地分支:${NC}"
                git branch -vv | sed 's/^/│ /'
                echo -e "├────────────────────────────────┤"
                echo -e "│ ${YELLOW}远程分支:${NC}"
                git branch -r | sed 's/^/│ /'
                echo -e "├────────────────────────────────┤"
                echo -e "│ ${YELLOW}最近提交:${NC}"
                git --no-pager log -3 --oneline | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"
            })
            ;;
        2)
            echo -e "\n${BLUE}┌─────────── 创建分支 ───────────┐${NC}"
            echo -e "│ 1) 基于当前分支创建"
            echo -e "│ 2) 基于特定提交创建"
            echo -e "│ 3) 基于远程分支创建"
            echo -e "└────────────────────────────────┘"
            read -p "请选择创建方式 [1-3]: " create_type

            case $create_type in
            1)
                read -p "输入新分支名称: " new_branch
                (cd "$project_path" && {
                    if git checkout -b "$new_branch"; then
                        echo -e "${GREEN}✓ 分支 '$new_branch' 创建成功${NC}"
                    else
                        echo -e "${RED}✗ 分支创建失败${NC}"
                    fi
                })
                ;;
            2)
                echo -e "\n${YELLOW}最近的提交记录:${NC}"
                (cd "$project_path" && git --no-pager log -5 --oneline)
                read -p "输入提交哈希: " commit_hash
                read -p "输入新分支名称: " new_branch
                (cd "$project_path" && {
                    if git checkout -b "$new_branch" "$commit_hash"; then
                        echo -e "${GREEN}✓ 分支 '$new_branch' 创建成功${NC}"
                    else
                        echo -e "${RED}✗ 分支创建失败${NC}"
                    fi
                })
                ;;
            3)
                echo -e "\n${YELLOW}可用的远程分支:${NC}"
                (cd "$project_path" && git branch -r)
                read -p "输入远程分支名称(例如 origin/main): " remote_branch
                read -p "输入新的本地分支名称: " new_branch
                (cd "$project_path" && {
                    if git checkout -b "$new_branch" "$remote_branch"; then
                        echo -e "${GREEN}✓ 分支 '$new_branch' 创建成功${NC}"
                    else
                        echo -e "${RED}✗ 分支创建失败${NC}"
                    fi
                })
                ;;
            esac
            ;;
        3)
            echo -e "\n${BLUE}┌─────────── 切换分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}可用分支:${NC}"
                git branch | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"

                read -p "输入要切换的分支名称: " switch_branch
                if [[ -n "$(git status --porcelain)" ]]; then
                    echo -e "${YELLOW}警告: 当前分支有未提交的更改${NC}"
                    echo -e "1) 储藏更改后切换"
                    echo -e "2) 强制切换（可能丢失更改）"
                    echo -e "3) 取消切换"
                    read -p "请选择操作 [1-3]: " stash_choice

                    case $stash_choice in
                    1)
                        git stash save "自动储藏于 $(date '+%Y-%m-%d %H:%M:%S')"
                        if git checkout "$switch_branch"; then
                            echo -e "${GREEN}✓ 已切换到分支 '$switch_branch'${NC}"
                            echo -e "${YELLOW}提示: 使用 'git stash pop' 恢复储藏的更改${NC}"
                        fi
                        ;;
                    2)
                        if git checkout -f "$switch_branch"; then
                            echo -e "${GREEN}✓ 已强制切换到分支 '$switch_branch'${NC}"
                        fi
                        ;;
                    3)
                        echo -e "${YELLOW}已取消切换${NC}"
                        ;;
                    esac
                else
                    if git checkout "$switch_branch"; then
                        echo -e "${GREEN}✓ 已切换到分支 '$switch_branch'${NC}"
                    fi
                fi
            })
            ;;
        4)
            echo -e "\n${BLUE}┌─────────── 删除分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}可删除的分支:${NC}"
                git branch | grep -v "\*" | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"

                read -p "输入要删除的分支名称: " del_branch

                if [[ "$del_branch" == "$current_branch" ]]; then
                    echo -e "${RED}错误: 不能删除当前分支${NC}"
                else
                    echo -e "${RED}警告: 此操作将删除分支！${NC}"
                    echo -e "1) 安全删除（仅删除已合并的分支）"
                    echo -e "2) 强制删除"
                    echo -e "3) 取消操作"
                    read -p "请选择删除方式 [1-3]: " del_type

                    case $del_type in
                    1)
                        if git branch -d "$del_branch"; then
                            echo -e "${GREEN}✓ 分支 '$del_branch' 已删除${NC}"
                        else
                            echo -e "${RED}✗ 删除失败，分支可能未完全合并${NC}"
                        fi
                        ;;
                    2)
                        echo -e "${RED}警告: 强制删除将丢失未合并的更改！${NC}"
                        read -p "确认强制删除？(y/n): " confirm_force
                        if [[ $confirm_force == "y" ]]; then
                            if git branch -D "$del_branch"; then
                                echo -e "${GREEN}✓ 分支 '$del_branch' 已强制删除${NC}"
                            fi
                        fi
                        ;;
                    3)
                        echo -e "${YELLOW}已取消删除操作${NC}"
                        ;;
                    esac
                fi
            })
            ;;
        5)
            echo -e "\n${BLUE}┌─────────── 重命名分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
                echo -e "└────────────────────────────────┘"
                read -p "输入新的分支名称: " new_name
                if git branch -m "$current_branch" "$new_name"; then
                    echo -e "${GREEN}✓ 分支已重命名为 '$new_name'${NC}"
                fi
            })
            ;;
        6)
            echo -e "\n${BLUE}┌─────────── 合并分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}可合并的分支:${NC}"
                git branch | grep -v "\*" | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"
                read -p "输入要合并的分支名称: " merge_branch

                echo -e "\n${YELLOW}选择合并策略:${NC}"
                echo -e "1) 普通合并"
                echo -e "2) 压缩合并（squash）"
                echo -e "3) 取消操作"
                read -p "请选择 [1-3]: " merge_type

                case $merge_type in
                1)
                    if git merge "$merge_branch"; then
                        echo -e "${GREEN}✓ 分支 '$merge_branch' 已合并${NC}"
                    fi
                    ;;
                2)
                    if git merge --squash "$merge_branch"; then
                        echo -e "${GREEN}✓ 分支 '$merge_branch' 已压缩合并${NC}"
                        echo -e "${YELLOW}请执行 commit 来完成合并${NC}"
                    fi
                    ;;
                3)
                    echo -e "${YELLOW}已取消合并操作${NC}"
                    ;;
                esac
            })
            ;;
        7)
            echo -e "\n${BLUE}┌─────────── 拉取远程分支 ───────────┐${NC}"
            (cd "$project_path" && {
                git fetch --all
                echo -e "│ ${YELLOW}远程分支:${NC}"
                git branch -r | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"
                read -p "输入要拉取的远程分支名称(例如 origin/feature): " remote_branch
                if [[ $remote_branch == origin/* ]]; then
                    local_branch=${remote_branch#origin/}
                    if git checkout -b "$local_branch" "$remote_branch"; then
                        echo -e "${GREEN}✓ 已创建并切换到本地分支 '$local_branch'${NC}"
                    fi
                else
                    echo -e "${RED}✗ 无效的远程分支名称${NC}"
                fi
            })
            ;;
        8)
            echo -e "\n${BLUE}┌─────────── 推送本地分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
                echo -e "└────────────────────────────────┘"
                read -p "是否推送到远程? (y/n): " do_push
                if [[ $do_push == "y" ]]; then
                    if git push -u origin "$current_branch"; then
                        echo -e "${GREEN}✓ 分支已推送到远程${NC}"
                    fi
                fi
            })
            ;;
        9)
            echo -e "\n${BLUE}┌─────────── 设置上游分支 ───────────┐${NC}"
            (cd "$project_path" && {
                echo -e "│ ${YELLOW}远程分支:${NC}"
                git branch -r | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"
                read -p "输入上游分支名称(例如 origin/main): " upstream
                if git branch --set-upstream-to="$upstream" "$current_branch"; then
                    echo -e "${GREEN}✓ 已设置上游分支为 '$upstream'${NC}"
                fi
            })
            ;;
        0)
            break
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
        esac
        read -p "按回车键继续..."
    done
}

# 优化 commit_changes 函数
commit_changes() {
    local project_path="$1"
    echo -e "\n${YELLOW}┌─────────── 提交更改管理 ───────────┐${NC}"
    (cd "$project_path" && {
        # 显示当前状态
        echo -e "${BLUE}当前工作区状态:${NC}"
        echo -e "├────────────────────────────────┤"
        git status -s | while IFS= read -r line; do
            status=${line:0:2}
            file=${line:3}
            case $status in
            "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
            " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
            "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
            "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
            "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
            *) echo -e "│ $line" ;;
            esac
        done
        echo -e "├────────────────────────────────┤"

        # 显示暂存区信息
        echo -e "│ ${BLUE}暂存区概览${NC}"
        echo -e "├────────────────────────────────┤"
        if git diff --cached --quiet; then
            echo -e "│ ${YELLOW}暂存区为空${NC}"
        else
            # 获取暂存区文件统计
            staged_files=$(git diff --cached --numstat | awk '{added+=$1; removed+=$2} END {print added+removed}')
            staged_changes=$(git diff --cached --shortstat)

            # 美化展示暂存区信息
            echo -e "│ ${GREEN}待提交更改:${NC}"
            echo -e "│ ✦ 修改文件数: ${staged_files} 个"
            echo -e "│ ✦ 具体变更: ${staged_changes#* }"
        fi
        echo -e "├────────────────────────────────┤"

        # 显示最近一次提交
        echo -e "│ ${BLUE}最近提交记录${NC}"
        echo -e "├────────────────────────────────┤"
        last_commit=$(git log -1 --pretty=format:"%h")
        if [ -n "$last_commit" ]; then
            commit_time=$(git log -1 --pretty=format:"%cr")
            commit_author=$(git log -1 --pretty=format:"%an")
            commit_msg=$(git log -1 --pretty=format:"%s")

            echo -e "│ ${YELLOW}✦${NC} 提交哈希: ${last_commit}"
            echo -e "│ ${YELLOW}✦${NC} 提交时间: ${commit_time}"
            echo -e "│ ${YELLOW}✦${NC} 提交作者: ${commit_author}"
            echo -e "│ ${YELLOW}✦${NC} 提交说明: ${commit_msg}"
        else
            echo -e "│ ${YELLOW}仓库暂无提交记录${NC}"
        fi
        echo -e "├────────────────────────────────┤"

        # 显示操作菜单
        echo -e "│ ${YELLOW}请选择操作:${NC}"
        echo -e "│ ${YELLOW}1)${NC} ${GREEN}选择性暂存${NC}"
        echo -e "│ ${YELLOW}2)${NC} ${RED}取消暂存${NC}"
        echo -e "│ ${YELLOW}3)${NC} ${BLUE}取消操作${NC}"
        echo -e "└────────────────────────────────┘"
        read -p "输入选项 [1-3]: " stage_choice

        case $stage_choice in
        1)
            # 获取未暂存的文件列表
            declare -a unstaged_files=()
            while IFS= read -r file; do
                [[ -n "$file" ]] && unstaged_files+=("$file")
            done < <(git ls-files --modified --others --exclude-standard)

            if [ ${#unstaged_files[@]} -eq 0 ]; then
                echo -e "\n${YELLOW}⚠ 没有可暂存的文件${NC}"
                return
            fi

            echo -e "\n${BLUE}┌─────────── 可暂存的文件 ───────────┐${NC}"
            for i in "${!unstaged_files[@]}"; do
                echo -e "│ $((i + 1))) ${unstaged_files[$i]}"
            done
            echo -e "└────────────────────────────────┘"

            echo -e "\n${YELLOW}输入文件编号(多个用空格分隔,输入 a 全选,输入 q 退出):${NC}"
            read -p "> " file_selection

            if [[ $file_selection == "q" ]]; then
                echo -e "${YELLOW}已取消操作${NC}"
                return
            elif [[ $file_selection == "a" ]]; then
                git add .
                echo -e "${GREEN}✓ 已暂存所有文件${NC}"
            else
                for num in $file_selection; do
                    if [[ $num =~ ^[0-9]+$ ]] && [ $num -gt 0 ] && [ $num -le ${#unstaged_files[@]} ]; then
                        git add "${unstaged_files[$((num - 1))]}"
                        echo -e "${GREEN}✓ 已暂存: ${NC}${unstaged_files[$((num - 1))]}"
                    fi
                done
            fi
            ;;
        2)
            unstage_changes
            return
            ;;
        3)
            echo -e "${YELLOW}操作已取消${NC}"
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            return
            ;;
        esac

        # 显示暂存的更改
        echo -e "\n${BLUE}┌─────────── 已暂存更改 ───────────┐${NC}"
        git diff --cached --stat | sed 's/^/│ /'
        echo -e "└────────────────────────────────┘"

        # 提交类型选择
        echo -e "\n${YELLOW}请选择提交类型:${NC}"
        echo -e "${BLUE}┌─────────── 提交类型说明 ───────────┐${NC}"
        echo -e "│ feat:     新功能"
        echo -e "│ fix:      修复bug"
        echo -e "│ docs:     文档更改"
        echo -e "│ style:    代码格式(不影响代码运行的变动)"
        echo -e "│ refactor: 重构(既不是新增功能，也不是修改bug的代码变动)"
        echo -e "│ test:     增加测试"
        echo -e "│ chore:    构建过程或辅助工具的变动"
        echo -e "│ perf:     性能优化"
        echo -e "└────────────────────────────────┘"

        read -p "输入提交类型: " commit_type

        # 验证提交类型
        valid_types=("feat" "fix" "docs" "style" "refactor" "test" "chore" "perf")
        if [[ ! " ${valid_types[@]} " =~ " ${commit_type} " ]]; then
            echo -e "${RED}无效的提交类型！${NC}"
            return
        fi

        # 提交范围（可选）
        echo -e "\n${BLUE}提交范围说明：${NC}"
        echo -e "┌──────────────────────────────────────────"
        echo -e "│ 提交范围用于指定本次更改影响的模块/功能范围"
        echo -e "│ "
        echo -e "│ ${YELLOW}常见范围示例：${NC}"
        echo -e "│ • ${GREEN}core${NC}: 核心模块"
        echo -e "│ • ${GREEN}ui${NC}: 用户界面"
        echo -e "│ • ${GREEN}api${NC}: API接口"
        echo -e "│ • ${GREEN}auth${NC}: 认证功能"
        echo -e "│ • ${GREEN}db${NC}: 数据库"
        echo -e "│ • ${GREEN}config${NC}: 配置文件"
        echo -e "│ • ${GREEN}docs${NC}: 文档"
        echo -e "│ • ${GREEN}test${NC}: 测试"
        echo -e "│ • ${GREEN}deps${NC}: 依赖项"
        echo -e "│ "
        echo -e "│ ${CYAN}格式示例：${NC}"
        echo -e "│ feat(ui): 添加新的登录界面"
        echo -e "│ fix(api): 修复用户认证bug"
        echo -e "└──────────────────────────────────────────"

        # 读取提交范围
        read -p "请输入提交范围(可选,直接回车跳过): " commit_scope

        # 如果输入了范围，验证格式
        if [[ -n "$commit_scope" ]]; then
            # 检查范围格式是否合法（只允许小写字母、数字、连字符和下划线）
            if [[ ! "$commit_scope" =~ ^[a-z0-9_-]+$ ]]; then
                echo -e "${YELLOW}警告：范围格式不规范，建议只使用小写字母、数字、连字符和下划线${NC}"
                read -p "是否继续？(y/n): " continue_with_scope
                if [[ "$continue_with_scope" != "y" ]]; then
                    return 1
                fi
            fi

            # 显示最终格式
            echo -e "\n${GREEN}最终提交格式将为：${NC} $commit_type($commit_scope): <提交描述>"
        else
            echo -e "\n${GREEN}最终提交格式将为：${NC} $commit_type: <提交描述>"
        fi

        # 提交描述
        echo -e "\n${YELLOW}请输入提交描述:${NC}"
        read -p "描述: " commit_description

        if [[ -n "$commit_description" ]]; then
            # 构建提交信息
            commit_message="$commit_type"
            [[ -n "$commit_scope" ]] && commit_message="$commit_message($commit_scope)"
            commit_message="$commit_message: $commit_description"

            # 执行 git commit 并检查 pre-commit hook 是否成功
            if ! git commit -m "$commit_message"; then
                echo -e "\n${RED}✗ 提交失败！pre-commit hook 检查未通过${NC}"
                echo -e "${YELLOW}是否撤销之前的暂存和提交操作？(y/n)${NC}"
                read -p "> " undo_changes
                if [[ $undo_changes == "y" ]]; then
                    git reset HEAD
                    echo -e "${GREEN}✓ 已撤销暂存的更改${NC}"
                else
                    echo -e "${YELLOW}ℹ 暂存的更改已保留，请修复问题后重试${NC}"
                fi
                return
            fi

            echo -e "\n${GREEN}✓ 更改已提交${NC}"

            # 显示最新提交
            echo -e "\n${BLUE}最新提交详情:${NC}"
            git log -1 --pretty=format:"提交: %h%n作者: %an%n时间: %cr%n说明: %s" | sed 's/^/│ /'
            echo

            # 推送询问
            echo -e "\n${YELLOW}是否推送到远程仓库? (y/n)${NC}"
            read -p "> " do_push
            if [[ $do_push == "y" ]]; then
                current_branch=$(git rev-parse --abbrev-ref HEAD)
                echo -e "\n${BLUE}推送到分支: ${NC}$current_branch"
                if git push origin "$current_branch"; then
                    echo -e "${GREEN}✓ 推送成功${NC}"
                else
                    echo -e "${RED}✗ 推送失败，请检查错误信息${NC}"
                    echo -e "\n${YELLOW}是否使用 --no-verify 标志强制推送? (y/n)${NC}"
                    read -p "> " force_push
                    if [[ $force_push == "y" ]]; then
                        if git push --no-verify origin "$current_branch"; then
                            echo -e "${GREEN}✓ 强制推送成功${NC}"
                        else
                            echo -e "${RED}✗ 强制推送失败${NC}"
                        fi
                    else
                        echo -e "${YELLOW}ℹ 强制推送已取消${NC}"
                    fi
                fi
            else
                echo -e "${YELLOW}ℹ 推送已取消，记得稍后推送更改${NC}"
            fi
        else
            echo -e "${RED}✗ 提交描述不能为空，操作已取消${NC}"
        fi
    })
    read -p "按回车键继续..."
}

# 新增：取消暂存功能
unstage_changes() {
    echo -e "\n${BLUE}┌─────────── 取消暂存管理 ───────────┐${NC}"

    # 检查是否有暂存的更改
    if ! git diff --cached --quiet; then
        # 显示已暂存文件的美化列表
        echo -e "│ ${GREEN}已暂存的文件:${NC}"
        echo -e "├────────────────────────────────┤"
        git diff --cached --stat | while IFS= read -r line; do
            echo -e "│ $line"
        done
        echo -e "├────────────────────────────────┤"

        # 显示操作菜单
        echo -e "│ ${YELLOW}请选择操作:${NC}"
        echo -e "│ 1) 选择性取消暂存"
        echo -e "│ 2) 返回"
        echo -e "└────────────────────────────────┘"
        read -p "输入选项 [1-2]: " unstage_choice

        case $unstage_choice in
        1)
            # 获取暂存的文件列表
            declare -a staged_files=()
            while IFS= read -r file; do
                [[ -n "$file" ]] && staged_files+=("$file")
            done < <(git diff --cached --name-only)

            if [ ${#staged_files[@]} -eq 0 ]; then
                echo -e "\n${YELLOW}⚠ 没有可取消暂存的文件${NC}"
                return
            fi

            # 显示文件列表
            echo -e "\n${BLUE}┌─────────── 已暂存的文件 ───────────┐${NC}"
            for i in "${!staged_files[@]}"; do
                echo -e "│ $((i + 1))) ${staged_files[$i]}"
            done
            echo -e "└────────────────────────────────┘"

            echo -e "\n${YELLOW}输入文件编号(多个用空格分隔,输入 a 全选,输入 q 退出):${NC}"
            read -p "> " file_selection

            if [[ $file_selection == "q" ]]; then
                echo -e "${YELLOW}ℹ 操作已取消${NC}"
                return
            elif [[ $file_selection == "a" ]]; then
                git reset HEAD
                echo -e "\n${GREEN}✓ 已取消所有暂存${NC}"
            else
                for num in $file_selection; do
                    if [[ $num =~ ^[0-9]+$ ]] && [ $num -gt 0 ] && [ $num -le ${#staged_files[@]} ]; then
                        file_to_unstage="${staged_files[$((num - 1))]}"
                        git reset HEAD "$file_to_unstage"
                        echo -e "${GREEN}✓ 已取消暂存:${NC} $file_to_unstage"
                    else
                        echo -e "${RED}✗ 无效的文件编号:${NC} $num"
                    fi
                done
            fi
            ;;
        2)
            echo -e "${YELLOW}ℹ 操作已取消${NC}"
            return
            ;;
        *)
            echo -e "${RED}✗ 无效的选择${NC}"
            return
            ;;
        esac

        # 显示当前状态
        echo -e "\n${BLUE}┌─────────── 当前状态 ───────────┐${NC}"
        git status -s | while IFS= read -r line; do
            status=${line:0:2}
            file=${line:3}
            case $status in
            "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
            " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
            "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
            "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
            "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
            *) echo -e "│ $line" ;;
            esac
        done
        echo -e "└────────────────────────────────┘"
    else
        echo -e "│ ${YELLOW}⚠ 当前没有暂存的更改${NC}"
        echo -e "└────────────────────────────────┘"
    fi

    read -p "按回车键继续..."
}

view_logs() {
    local project_path="$1"
    # 先切换到项目目录
    cd "$project_path" || return 1

    while true; do
        echo -e "\n${BLUE}┌─────────── 提交历史查看 ───────────┐${NC}"
        # 获取当前分支信息
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        echo -e "│ ${YELLOW}当前分支:${NC} $current_branch"
        echo -e "├────────────────────────────────┤"

        echo -e "│ ${YELLOW}查看选项:${NC}"
        echo -e "│ 1) 简洁历史"
        echo -e "│ 2) 详细历史"
        echo -e "│ 3) 图形化历史"
        echo -e "│ 4) 文件变更历史"
        echo -e "│ 5) 作者统计"
        echo -e "│ 6) 高级搜索"
        echo -e "│ 7) 分支比较"
        echo -e "│ 0) 返回上级菜单"
        echo -e "└────────────────────────────────┘"

        read -p "请选择查看方式 [0-7]: " log_choice

        case $log_choice in
        1)
            echo -e "\n${BLUE}┌─────────── 简洁历史 ───────────┐${NC}"
            echo -e "│ ${YELLOW}显示最近提交记录${NC}"
            read -p "显示条数 [默认10]: " log_count
            log_count=${log_count:-10}
            echo -e "└────────────────────────────────┘\n"

            git --no-pager log -n "$log_count" --pretty=format:"%C(yellow)%h%Creset - %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset" | sed 's/^/  /'
            echo -e "\n"
            read -p "按回车键继续..."
            ;;
        2)
            echo -e "\n${BLUE}┌─────────── 详细历史 ───────────┐${NC}"
            echo -e "│ ${YELLOW}显示详细提交信息${NC}"
            read -p "显示条数 [默认2]: " log_count
            log_count=${log_count:-2}
            echo -e "└────────────────────────────────┘\n"

            git --no-pager log -n "$log_count" --pretty=format:"提交: %h%n作者: %an <%ae>%n日期: %cd%n标题: %s%n%n%b%n----------------------------------------" --date=format:"%Y-%m-%d %H:%M:%S"
            ;;
        3)
            echo -e "\n${BLUE}┌─────────── 图形化历史 ───────────┐${NC}"
            echo -e "│ ${YELLOW}显示分支图形历史${NC}"
            read -p "显示条数 [默认20]: " log_count
            log_count=${log_count:-20}
            echo -e "└────────────────────────────────┘\n"

            git --no-pager log -n "$log_count" --graph --pretty=format:"%C(yellow)%h%Creset -%C(bold blue)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit --date=relative
            ;;
        4)
            echo -e "\n${BLUE}┌─────────── 文件变更历史 ───────────┐${NC}"
            echo -e "│ ${YELLOW}1)${NC} 查看特定文件历史"
            echo -e "│ ${YELLOW}2)${NC} 查看最近修改的文件"
            echo -e "│ ${YELLOW}3)${NC} 查看特定提交的文件变更"
            echo -e "└────────────────────────────────┘"

            read -p "请选择 [1-3]: " file_choice
            case $file_choice in
            1)
                read -p "输入文件路径: " file_path
                if [[ -f "$file_path" ]]; then
                    git --no-pager log --follow --pretty=format:"%h - %s (%cr) <%an>" -- "$file_path"
                else
                    echo -e "${RED}文件不存在${NC}"
                fi
                ;;
            2)
                read -p "显示最近几天的变更 [默认7]: " days
                days=${days:-7}
                git --no-pager log --pretty=format: --name-only --since="$days days ago" | sort | uniq -c | sort -rn | head -n 10
                ;;
            3)
                git --no-pager log --pretty=oneline -n 5
                read -p "输入提交哈希: " commit_hash
                git --no-pager show --stat --pretty=format:"%h - %s" "$commit_hash"
                ;;
            esac
            ;;
        5)
            echo -e "\n${BLUE}┌─────────── 作者统计 ───────────┐${NC}"
            echo -e "│ ${YELLOW}1)${NC} 提交数量统计"
            echo -e "│ ${YELLOW}2)${NC} 代码行数统计"
            echo -e "└────────────────────────────────┘"

            read -p "请选择 [1-2]: " stat_choice
            case $stat_choice in
            1)
                git --no-pager shortlog -sn --all
                ;;
            2)
                git --no-pager log --author="$(git config user.name)" --pretty=tformat: --numstat | awk '{ add += $1; subs += $2; loc += $1 - $2 } END { printf "添加行数: %s\n删除行数: %s\n总计: %s\n", add, subs, loc }'
                ;;
            esac
            ;;
        6)
            echo -e "\n${BLUE}┌─────────── 高级搜索 ───────────┐${NC}"
            echo -e "│ ${YELLOW}1)${NC} 按提交信息搜索"
            echo -e "│ ${YELLOW}2)${NC} 按作者搜索"
            echo -e "│ ${YELLOW}3)${NC} 按日期搜索"
            echo -e "│ ${YELLOW}4)${NC} 按内容搜索"
            echo -e "└────────────────────────────────┘"

            read -p "请选择搜索方式 [1-4]: " search_choice
            case $search_choice in
            1)
                read -p "输入搜索关键词: " search_term
                git --no-pager log --grep="$search_term" --pretty=format:"%h - %s (%cr) <%an>"
                ;;
            2)
                read -p "输入作者名称: " author_name
                git --no-pager log --author="$author_name" --pretty=format:"%h - %s (%cr)"
                ;;
            3)
                read -p "输入起始日期 (YYYY-MM-DD): " start_date
                read -p "输入结束日期 (YYYY-MM-DD): " end_date
                git --no-pager log --since="$start_date" --until="$end_date" --pretty=format:"%h - %s (%cr) <%an>"
                ;;
            4)
                read -p "输入搜索内容: " search_content
                git --no-pager log -S "$search_content" --pretty=format:"%h - %s (%cr) <%an>"
                ;;
            esac
            ;;
        7)
            echo -e "\n${BLUE}┌─────────── 分支比较 ───────────┐${NC}"
            echo -e "│ ${YELLOW}可用分支:${NC}"
            git --no-pager branch | sed 's/^/│ /'
            echo -e "└────────────────────────────────┘"

            read -p "输入第一个分支名称: " branch1
            read -p "输入第二个分支名称: " branch2

            echo -e "\n${YELLOW}比较选项:${NC}"
            echo -e "1) 查看差异提交"
            echo -e "2) 查看文件差异"
            read -p "请选择 [1-2]: " diff_choice

            case $diff_choice in
            1)
                git --no-pager log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit "$branch1..$branch2"
                ;;
            2)
                git --no-pager diff --stat "$branch1..$branch2"
                ;;
            esac
            ;;
        0)
            # 返回上级菜单前切换回原目录
            cd - >/dev/null
            return
            ;;
        *)
            echo -e "${RED}无效选择${NC}"
            ;;
        esac
        read -p "按回车键继续..."
    done
}

sync_remote_branches() {
    local project_path="$1"
    echo -e "\n${YELLOW}同步远程分支...${NC}"
    (cd "$project_path" && {
        git fetch --prune
        echo -e "${GREEN}已同步远程分支信息${NC}"
        echo -e "\n${YELLOW}远程分支状态：${NC}"
        git remote show origin
    })
    read -p "按回车键继续..."
}

open_project_directory() {
    local project_path="$1"
    echo -e "\n${YELLOW}打开项目目录...${NC}"
    open "$project_path"
    read -p "按回车键继续..."
}

# 优化：管理最近提交的函数，支持取消指定提交
manage_recent_commits() {
    local project_path="$1"
    cd "$project_path" || return 1

    while true; do
        echo -e "\n${YELLOW}┌─────────── 提交管理 ───────────┐${NC}"
        # 获取当前分支
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        echo -e "│ ${BLUE}当前分支:${NC} $current_branch"
        echo -e "├────────────────────────────────┤"

        # 获取未推送的提交
        unpushed_commits=$(git log @{u}.. --oneline 2>/dev/null)
        if [[ -n "$unpushed_commits" ]]; then
            echo -e "│ ${YELLOW}未推送的提交:${NC}"
            echo "$unpushed_commits" | while IFS= read -r line; do
                echo -e "│ • $line"
            done
            echo -e "├────────────────────────────────┤"
        fi

        # 显示最近的提交记录（带编号）
        echo -e "│ ${BLUE}最近提交记录:${NC}"
        declare -a commit_hashes=()
        declare -a commit_messages=()
        while IFS= read -r line; do
            hash=$(echo "$line" | cut -d' ' -f1)
            msg=$(echo "$line" | cut -d' ' -f2-)
            commit_hashes+=("$hash")
            commit_messages+=("$msg")
            echo -e "│ ${YELLOW}$((${#commit_hashes[@]}))${NC}) $hash - $msg"
        done < <(git log -10 --pretty=format:"%h %s %C(green)(%cr)%Creset %C(blue)<%an>%Creset" --abbrev-commit)

        echo -e "├────────────────────────────────┤"
        echo -e "│ ${YELLOW}操作选项:${NC}"
        echo -e "│ 1) 撤销最近的提交"
        echo -e "│ 2) 回退到指定提交"
        echo -e "│ 3) 查看提交详情"
        echo -e "│ 4) 修改最近提交"
        echo -e "│ 5) 返回上级菜单"
        echo -e "└────────────────────────────────┘"

        read -p "请选择操作 [1-5]: " commit_op_choice

        case $commit_op_choice in
        1)
            echo -e "\n${YELLOW}┌─────────── 撤销提交 ───────────┐${NC}"
            echo -e "│ 1) 仅撤销提交，保留更改"
            echo -e "│ 2) 完全撤销提交和更改"
            echo -e "└────────────────────────────────┘"
            read -p "请选择 [1-2]: " revert_choice

            case $revert_choice in
            1)
                if git reset --soft HEAD^; then
                    echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                    echo -e "│ ✓ 已撤销最近的提交"
                    echo -e "│ ✓ 更改已保留在暂存区"
                    echo -e "│ ✓ 可以重新提交或修改"
                    echo -e "└────────────────────────────────┘"
                else
                    echo -e "${RED}✗ 撤销失败${NC}"
                fi
                ;;
            2)
                echo -e "\n${RED}┌─────────── 警告 ───────────┐${NC}"
                echo -e "│ ⚠ 此操作将永久删除最近的提交和更改！"
                echo -e "│ ⚠ 此操作无法撤销！"
                echo -e "└────────────────────────────────┘"
                read -p "确认继续？(y/n): " confirm
                if [[ $confirm == "y" ]]; then
                    if git reset --hard HEAD^; then
                        echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                        echo -e "│ ✓ 已完全撤销最近的提交和更改"
                        echo -e "└────────────────────────────────┘"
                    else
                        echo -e "${RED}✗ 撤销失败${NC}"
                    fi
                fi
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
            esac
            ;;

        2)
            echo -e "\n${YELLOW}请选择要回退到的提交编号 [1-${#commit_hashes[@]}]:${NC}"
            read -p "> " commit_number

            if [[ $commit_number =~ ^[0-9]+$ ]] && [ "$commit_number" -le "${#commit_hashes[@]}" ] && [ "$commit_number" -gt 0 ]; then
                selected_hash="${commit_hashes[$((commit_number - 1))]}"
                selected_msg="${commit_messages[$((commit_number - 1))]}"

                echo -e "\n${BLUE}┌─────────── 选中的提交 ───────────┐${NC}"
                echo -e "│ 提交: $selected_hash"
                echo -e "│ 说明: $selected_msg"
                echo -e "└────────────────────────────────┘"

                echo -e "\n${YELLOW}回退选项:${NC}"
                echo -e "1) 保留更改（soft reset）"
                echo -e "2) 丢弃更改（hard reset）"
                read -p "请选择 [1-2]: " reset_choice

                case $reset_choice in
                1)
                    if git reset --soft "$selected_hash"; then
                        echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                        echo -e "│ ✓ 已回退到选中的提交"
                        echo -e "│ ✓ 更改已保留在暂存区"
                        echo -e "└────────────────────────────────┘"
                    else
                        echo -e "${RED}✗ 回退失败${NC}"
                    fi
                    ;;
                2)
                    echo -e "\n${RED}┌─────────── 警告 ───────────┐${NC}"
                    echo -e "│ ⚠ 此操作将永久删除该提交之后的所有更改！"
                    echo -e "│ ⚠ 此操作无法撤销！"
                    echo -e "└────────────────────────────────┘"
                    read -p "确认继续？(y/n): " confirm
                    if [[ $confirm == "y" ]]; then
                        if git reset --hard "$selected_hash"; then
                            echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                            echo -e "│ ✓ 已回退到选中的提交"
                            echo -e "│ ✓ 之后的所有更改已被删除"
                            echo -e "└────────────────────────────────┘"
                        else
                            echo -e "${RED}✗ 回退失败${NC}"
                        fi
                    fi
                    ;;
                *)
                    echo -e "${RED}无效的选择${NC}"
                    ;;
                esac
            else
                echo -e "${RED}✗ 无效的提交编号${NC}"
            fi
            ;;

        3)
            echo -e "\n${YELLOW}请选择要查看的提交编号 [1-${#commit_hashes[@]}]:${NC}"
            read -p "> " view_number

            if [[ $view_number =~ ^[0-9]+$ ]] && [ "$view_number" -le "${#commit_hashes[@]}" ] && [ "$view_number" -gt 0 ]; then
                selected_hash="${commit_hashes[$((view_number - 1))]}"

                echo -e "\n${BLUE}┌─────────── 提交详情 ───────────┐${NC}"
                # 获取提交的详细信息
                commit_info=$(git show --pretty=format:"提交: %h%n作者: %an%n邮箱: %ae%n日期: %ad%n说明: %s%n%n" --date=format:"%Y-%m-%d %H:%M:%S" "$selected_hash")
                echo -e "│ ${YELLOW}基本信息:${NC}"
                echo "$commit_info" | sed 's/^/│ /'

                echo -e "│"
                echo -e "│ ${YELLOW}更改统计:${NC}"
                git show --stat "$selected_hash" | sed 's/^/│ /'

                echo -e "│"
                echo -e "│ ${YELLOW}详细更改:${NC}"
                git show --color "$selected_hash" | sed 's/^/│ /'
                echo -e "└────────────────────────────────┘"
            else
                echo -e "${RED}✗ 无效的提交编号${NC}"
            fi
            ;;

        4)
            echo -e "\n${YELLOW}┌─────────── 修改提交 ───────────┐${NC}"
            echo -e "│ 1) 修改最近提交的说明"
            echo -e "│ 2) 追加更改到最近提交"
            echo -e "└────────────────────────────────┘"
            read -p "请选择 [1-2]: " amend_choice

            case $amend_choice in
            1)
                # 获取当前提交信息
                current_msg=$(git log -1 --pretty=format:"%s")
                echo -e "\n${BLUE}当前提交说明:${NC} $current_msg"
                echo -e "${YELLOW}请输入新的提交说明:${NC}"
                read -p "> " new_msg

                if [[ -n "$new_msg" ]]; then
                    if git commit --amend -m "$new_msg"; then
                        echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                        echo -e "│ ✓ 已修改提交说明"
                        echo -e "│ ✓ 新说明: $new_msg"
                        echo -e "└────────────────────────────────┘"
                    else
                        echo -e "${RED}✗ 修改失败${NC}"
                    fi
                else
                    echo -e "${RED}✗ 提交说明不能为空${NC}"
                fi
                ;;
            2)
                echo -e "\n${BLUE}┌─────────── 当前更改 ───────────┐${NC}"
                git status -s | while IFS= read -r line; do
                    status=${line:0:2}
                    file=${line:3}
                    case $status in
                    "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
                    " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
                    "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
                    "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
                    "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
                    *) echo -e "│ $line" ;;
                    esac
                done
                echo -e "└────────────────────────────────┘"

                echo -e "\n${YELLOW}是否暂存所有更改？(y/n)${NC}"
                read -p "> " stage_all

                if [[ $stage_all == "y" ]]; then
                    git add .
                    echo -e "${GREEN}✓ 已暂存所有更改${NC}"
                else
                    echo -e "\n${YELLOW}请手动暂存需要追加的更改后继续${NC}"
                    read -p "准备好后按回车继续..."
                fi

                if git commit --amend --no-edit; then
                    echo -e "\n${GREEN}┌─────────── 操作成功 ───────────┐${NC}"
                    echo -e "│ ✓ 已将更改追加到最近的提交"
                    echo -e "└────────────────────────────────┘"
                else
                    echo -e "${RED}✗ 追加失败${NC}"
                fi
                ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                ;;
            esac
            ;;

        5)
            cd - >/dev/null
            return
            ;;

        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
        esac

        # 操作后显示当前状态
        if [[ $commit_op_choice != "5" ]]; then
            echo -e "\n${BLUE}┌─────────── 当前状态 ───────────┐${NC}"
            git status -s | while IFS= read -r line; do
                status=${line:0:2}
                file=${line:3}
                case $status in
                "M "*) echo -e "│ ${YELLOW}修改: ${NC}$file" ;;
                " M"*) echo -e "│ ${GREEN}待暂存: ${NC}$file" ;;
                "A "*) echo -e "│ ${GREEN}新增: ${NC}$file" ;;
                "D "*) echo -e "│ ${RED}删除: ${NC}$file" ;;
                "??"*) echo -e "│ ${BLUE}未跟踪: ${NC}$file" ;;
                *) echo -e "│ $line" ;;
                esac
            done
            echo -e "└────────────────────────────────┘"
            read -p "按回车键继续..."
        fi
    done
    cd - >/dev/null
}

# 启动脚本
show_main_menu
