#!/bin/bash

# 游戏服务器部署脚本
# 使用方法：./deploy-gameserver.sh [选项]

set -e

# 默认配置
INVENTORY_FILE="inventory/gameservers.yml"
PLAYBOOK_FILE="playbook/game-deploy.yml"
LIMIT=""
TAGS=""
CHECK_MODE=""
VERBOSE=""
EXTRA_VARS=""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo -e "${BLUE}游戏服务器部署脚本${NC}"
    echo "用法: $0 [选项]"
    echo ""
    echo "必需参数："
    echo "  -n, --game-name GAME      游戏名称 (如: tongits)"
    echo "  -i, --game-id ID          游戏ID (如: 10001)"
    echo "  -r, --room-num NUM        房间号 (如: 1)"
    echo "  -g, --game-room ROOM      游戏房间标识 (如: room-00001)"
    echo ""
    echo "可选参数："
    echo "  -h, --host HOST           目标主机 (默认: 所有gameservers)"
    echo "  -t, --tags TAGS           只运行指定标签的任务"
    echo "  -c, --check               检查模式（不实际执行）"
    echo "  -v, --verbose             详细输出"
    echo "  -s, --start               部署后自动启动服务"
    echo "  --help                    显示此帮助信息"
    echo ""
    echo "示例："
    echo "  # 部署 tongits 游戏到所有服务器"
    echo "  $0 -n tongits -i 10001 -r 1 -g room-00001"
    echo ""
    echo "  # 只部署到 sg-game-01 服务器"
    echo "  $0 -n tongits -i 10001 -r 1 -g room-00001 -h sg-game-01"
    echo ""
    echo "  # 只运行编译步骤"
    echo "  $0 -n tongits -i 10001 -r 1 -g room-00001 -t compile"
    echo ""
    echo "  # 检查模式（不实际执行）"
    echo "  $0 -n tongits -i 10001 -r 1 -g room-00001 -c"
    echo ""
    echo "  # 部署并自动启动服务"
    echo "  $0 -n tongits -i 10001 -r 1 -g room-00001 -s"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--game-name)
            GAME_NAME="$2"
            shift 2
            ;;
        -i|--game-id)
            GAME_ID="$2"
            shift 2
            ;;
        -r|--room-num)
            ROOM_NUM="$2"
            shift 2
            ;;
        -g|--game-room)
            GAME_ROOM="$2"
            shift 2
            ;;
        -h|--host)
            LIMIT="--limit $2"
            shift 2
            ;;
        -t|--tags)
            TAGS="--tags $2"
            shift 2
            ;;
        -c|--check)
            CHECK_MODE="--check"
            shift
            ;;
        -v|--verbose)
            VERBOSE="-vvv"
            shift
            ;;
        -s|--start)
            EXTRA_VARS="${EXTRA_VARS} gameserver_start_supervisor=true"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 未知参数 $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查必需参数
if [[ -z "$GAME_NAME" || -z "$GAME_ID" || -z "$ROOM_NUM" || -z "$GAME_ROOM" ]]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    echo ""
    show_help
    exit 1
fi

# 构建额外变量
EXTRA_VARS="game_name=$GAME_NAME game_id=$GAME_ID room_num=$ROOM_NUM game_room=$GAME_ROOM $EXTRA_VARS"

# 检查文件是否存在
if [[ ! -f "$INVENTORY_FILE" ]]; then
    echo -e "${RED}错误: Inventory 文件不存在: $INVENTORY_FILE${NC}"
    exit 1
fi

if [[ ! -f "$PLAYBOOK_FILE" ]]; then
    echo -e "${RED}错误: Playbook 文件不存在: $PLAYBOOK_FILE${NC}"
    exit 1
fi

# 显示部署信息
echo -e "${BLUE}==================== 部署信息 ====================${NC}"
echo -e "${GREEN}游戏名称:${NC} $GAME_NAME"
echo -e "${GREEN}游戏ID:${NC} $GAME_ID"
echo -e "${GREEN}房间号:${NC} $ROOM_NUM"
echo -e "${GREEN}游戏房间:${NC} $GAME_ROOM"
echo -e "${GREEN}Inventory:${NC} $INVENTORY_FILE"
echo -e "${GREEN}Playbook:${NC} $PLAYBOOK_FILE"
if [[ -n "$LIMIT" ]]; then
    echo -e "${GREEN}目标主机:${NC} ${LIMIT#--limit }"
fi
if [[ -n "$TAGS" ]]; then
    echo -e "${GREEN}执行标签:${NC} ${TAGS#--tags }"
fi
if [[ -n "$CHECK_MODE" ]]; then
    echo -e "${YELLOW}模式:${NC} 检查模式（不实际执行）"
fi
echo -e "${BLUE}================================================${NC}"

# 确认执行
if [[ -z "$CHECK_MODE" ]]; then
    echo -e "${YELLOW}确认要执行部署吗？(y/N)${NC}"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${BLUE}部署已取消${NC}"
        exit 0
    fi
fi

# 构建完整命令
ANSIBLE_CMD="ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE -e \"$EXTRA_VARS\" $LIMIT $TAGS $CHECK_MODE $VERBOSE"

echo -e "${BLUE}执行命令:${NC} $ANSIBLE_CMD"
echo ""

# 执行 ansible-playbook
eval $ANSIBLE_CMD

# 检查执行结果
if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 部署成功完成！${NC}"
    
    if [[ -z "$CHECK_MODE" ]]; then
        echo ""
        echo -e "${BLUE}常用管理命令:${NC}"
        echo -e "${GREEN}查看状态:${NC} sudo supervisorctl status ${ROOM_NUM}-${GAME_NAME}-${GAME_ROOM}"
        echo -e "${GREEN}启动服务:${NC} sudo supervisorctl start ${ROOM_NUM}-${GAME_NAME}-${GAME_ROOM}"
        echo -e "${GREEN}停止服务:${NC} sudo supervisorctl stop ${ROOM_NUM}-${GAME_NAME}-${GAME_ROOM}"
        echo -e "${GREEN}查看日志:${NC} sudo tail -f /usr/local/game-server/${GAME_ROOM}/${GAME_NAME}/log/${ROOM_NUM}-${GAME_NAME}-${GAME_ROOM}-access.log"
    fi
else
    echo ""
    echo -e "${RED}❌ 部署失败！请检查上面的错误信息。${NC}"
    exit 1
fi
