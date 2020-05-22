#!/bin/bash

welcome(){
    FILE=`dirname $0`/README
    echo "-----------------------------------"
    echo "使用前请用以下命令安装依赖项："
    echo "sudo apt-get install pip3(可能需要) "
    echo "pip3 install you-get"
    echo "pip3 install urllib3"
    echo "pip3 install matplotlib"
    echo "pip3 install scipy"
    echo "pip3 install certifi"
    echo "sudo apt-get install zenity(可能需要) "
    echo "-----------------------------------"
    zenity --text-info \
        --width=300 --height=500 \
        --title="Welcome" \
        --filename=$FILE \
        2>/dev/null
    # 2>/dev/null 用于忽略zenity的警告信息
    case $? in
        0) echo "开始程序"; echo "--------";;
        1) echo "程序退出"; exit;;
        -1) echo "发生了意外错误"; exit;;
    esac
}

show_up_list(){
    # 读入up_list的数据，显示up_list列表
    # 把输入中的 ` （分隔符）替换为换行，以匹配zenity的输入
    local up=$(cat up_list | sed 's/`/\n/g' | zenity --list \
        --title="up主名单" \
        --width=350 --height=500 \
        --text="以下是您所关注的Up\n选中一位UP可进行进一步操作:" \
        --title="关注列表" \
        --column="ID号" --column="名称" \
        2>/dev/null)

    # 用户点击了“取消”或右上角关闭，返回
    if [ $? -eq 1 ]; then return; fi
    # 没有选中up，返回
    if [ -z $up ]; then return; fi
    
    local choice=$(zenity --list \
        --title="请选择操作" \
        --width=350 --height=300 \
        --column="序号" --column="操作" \
        1 "查看信息和头像" \
        2 "进入视频列表" \
        3 "查看涨粉动态" \
        2>/dev/null)
    # 用户点击了“取消”或右上角关闭，返回
    if [ $? -eq 1 ]; then return; fi
    # 没有选中选项，返回
    if [ -z $choice ]; then return; fi
    show_info(){
        str=$(python3 script.py get_up_info $1)
        OLD_IFS=$IFS
        IFS='`'
        arr=($str)
        IFS=$OLD_IFS
        # arr[0]是要显示的信息，[1]是头像地址
        # 下载存储头像图片
        if [ ! -d "./pic_info/face" ]; then
            mkdir ./pic_info/face
        fi
        curl -o ./pic_info/face/$1 ${arr[1]}
        # 显示信息
        zenity --info --text="${arr[0]}" --width=400 2>/dev/null
        # 显示头像
        eog ./pic_info/face/$1
    }
    show_vedio_list(){
        echo "进入视频列表"
        echo "获取up的视频列表中……这将需要几秒钟"
        # 清空临时表单
        touch temp_list
        echo -n "" > temp_list
        python3 script.py get_vedio_list $1 | while read line
        do
            # 分割信息
            OLD_IFS=$IFS
            IFS='`'
            read -a strarr <<< "$line"
            IFS=$OLD_IFS
            # strarr[0] 是aid [1]是title [2]是creat_time(formatted) [3]是length [4]是播放量 [5]是封面地址
            echo "${strarr[0]}\`${strarr[1]}\`${strarr[3]}\`${strarr[4]}\`${strarr[2]}\`${strarr[5]}" >> temp_list
        done
        local aid=$(cat temp_list | sed 's/`/\n/g' | zenity --list \
        --width=1000 --height=700 \
        --title="视频列表" \
        --column="av号" --column="标题" --column="时长" --column="播放量" --column="发布时间" --column="封面地址" \
        2>/dev/null)
        # 用户点击了“取消”或右上角关闭，返回
        if [ $? -eq 1 ]; then return; fi
        # 没有选中选项，返回
        if [ -z $aid ]; then return; fi
        local choice=$(
            zenity --list \
            --width=350 --height=300 \
            --column="序号" --column="操作" \
            1 "查看视频信息和封面" \
            2 "在线播放" \
            3 "视频下载" \
            2>/dev/null
        )
         # 用户点击了“取消”或右上角关闭，返回
        if [ $? -eq 1 ]; then return; fi
        # 没有选中选项，返回
        if [ -z $aid ]; then return; fi
        show_vedio_info(){
            local intro=$(python3 script.py get_vedio_info $1)
            local str=$(grep "$1" temp_list)

            OLD_IFS=$IFS
            IFS='`'
            read -a info_arr <<< "$str"
            IFS=$OLD_IFS
            url="https:${info_arr[5]}"
            
            OLD_IFS=$IFS
            IFS='/'
            read -a url_arr <<< "$url"
            IFS=$OLD_IFS
            pic_name=${url_arr[5]}
            if [ ! -d "./pic_info/runtime_pic" ]; then
                mkdir ./pic_info/runtime_pic
            fi
            curl -o ./pic_info/runtime_pic/$pic_name $url
            zenity --info --text="${intro}" --width=400 2>/dev/null
            eog ./pic_info/runtime_pic/$pic_name
        }
        online_play(){
            x-www-browser "https://www.bilibili.com/video/av$1"
        }
        download_vedio(){
            you-get -o ./download_vedio/ "https://www.bilibili.com/video/av$1"
        }
        case $choice in
        1) show_vedio_info $aid;;
        2) online_play $aid;;
        3) download_vedio $aid;;
        esac
        rm -f temp_list
    }
    show_fans_pic(){
        python3 Draw_fanPic.py $1
    }
    case $choice in
    1) show_info $up;;
    2) show_vedio_list $up;;
    3) show_fans_pic $up;;
    esac
}
change_up_list(){
    online_import(){
        id=$(zenity --entry \
            --title="输入用户id" \
            --text="请输入您账号的id，将自动获取您的关注列表：\n注：用户id可在bilibili网页版个人空间的网页链接中找到"\
            2>/dev/null)
        if [ $? -eq 1 ] # 用户点击了“取消”或右上角关闭
        then
            return
        fi
        echo "导入中……这将需要几秒时间"
        python3 script.py get_subscribe_list $id > up_list
        zenity --info \
            --text="导入成功" \
            2>/dev/null
        echo "导入成功"
    }
    manually_import(){
        zenity --forms --title="添加up信息" \
            --text="输入要关注的up信息" \
            --separator="\`" \
            --add-entry="ID号" \
            --add-entry="名称" 2>/dev/null >> up_list
        case $? in
            0) echo "已添加";;
            1) echo "添加失败";;
            -1) echo "发生意外错误";;
        esac
    }
    unsubscribe(){
        local id=$(zenity --entry \
        --title="取消关注" \
        --text="请输入要取消关注up的id:" \
        2>/dev/null)
        if [ $? -eq 1 ]; then return; fi
        if [ -z $id ]; then return; fi
        sed -i "/^$id/d" ./up_list
        zenity --info --text="成功取消关注" 2>/dev/null
    }
    local choice=$(zenity --list --title="请选择操作" --width=250 --height=250 \
        --column="序号" --column="操作" \
        1 "在线导入" \
        2 "手动导入" \
        3 "取消关注" \
        2>/dev/null)
    if [ $? -eq 1 ]
    then
        echo "退出导入"
        return
    fi
    case $choice in
    1) online_import;;
    2) manually_import;;
    3) unsubscribe;;
    *) echo "没有选择"
    esac
}
up_monitor(){
    local choice=$(zenity --list \
        --title="up粉丝监控器" \
        --text="请选择您想执行的操作:" \
        --width=350 --height=300 \
        --column="序号" --column="操作" \
        1 "刷新up粉丝列表(单次)" \
        2 "开启后台自动监控" \
        3 "关闭后台自动监控" \
        4 "显示涨粉网页" \
        2>/dev/null)
    if [ $? -eq 1 ]; then return; fi
    if [ -z $choice ]; then return; fi
    flash_fans_info(){
        local time=$(date "+%Y-%m-%d %H:%M") # 获取当前时间（忽略获取每条数据的时间间隔）
        cat up_list | while read line
        do
            local id=$(echo $line | grep -P '^\d+' -o) # 获取id
            local name=${line:$[ ${#id} + 1 ]} # 获取up名称
            local fans=$(python3 script.py get_up_fans $id)
            echo "写入信息：$name,,$fans,$time"
            echo "$name,,$fans,$time" >> fans_info_all.csv
            echo "$fans,$time" >> ./fans_info/$id
            sleep 1s # 获取每条信息的时间间隔
        done
        echo "刷新完成"
    }
    kill_bk(){
        local str=$(ps -aux | grep "bash auto_info_getter.sh")
        local arr=($str)
        local flag=1
        local a=10
        while [ $flag -eq 1 ]
        do
        if [ "${arr[$a]}" = "bash" ]
        then
            kill ${arr[`expr $a - 9`]}
        else
            flag=-1
        fi
        a=`expr $a + 12`
        done
    }
    run_in_bk(){
        kill_bk
        nohup bash auto_info_getter.sh &
        zenity --info --text="后台开始执行脚本" 2>/dev/null
    }
    manual_kill_bk(){
        kill_bk
        echo "关闭了正在运行的后台脚本"
    }
    show_web(){
        base_dir=$(cd "$(dirname "$0")";pwd)
        x-www-browser "file://$base_dir/web_page/bargraph.html"
    }
    case $choice in
        1) flash_fans_info;;
        2) run_in_bk;;
        3) manual_kill_bk;;
        4) show_web;;
    esac
}
Choose(){
    choice=$(zenity --list \
        --title="主菜单" \
        --text="这里是程序的主菜单\n请选择您想执行的操作:" \
        --width=350 --height=300 \
        --column="序号" --column="操作" \
        1 "进入关注列表" \
        2 "修改关注列表" \
        3 "up粉丝监控器" \
        4 "退出"\
        2>/dev/null)
    if [ $? -eq 1 ] # 在选择窗口选了取消或右上角关闭，认为关闭程序
    then
        running_flag=-1
        echo "退出程序"
        return
    fi
    case $choice in
        1) show_up_list;;
        2) change_up_list;;
        3) up_monitor;;
        4) running_flag=-1; echo "退出程序";;
        *) echo "没有选中操作"
    esac
}


welcome # 开始界面
running_flag=1 # 1标志程序运行中，-1标志退出程序
while [ $running_flag -eq 1 ]
do
    Choose
done
