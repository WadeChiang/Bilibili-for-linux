flash_fans_info(){
    local time=$(date "+%Y-%m-%d %H:%M") # 获取当前时间（忽略获取每条数据的时间间隔）
    cat up_list | while read line
    do
        local id=$(echo $line | grep -P '^\d+' -o) # 获取id
        local name=${line:$[ ${#id} + 1 ]} # 获取up名称
        local fans=$(python3 script.py get_up_fans $id)
        echo "向csv写入一行：$name,,$fans,$time"
        echo "$name,,$fans,$time" >> fans_info_all.csv
        echo "$fans,$time" >> ./fans_info/$id
        sleep 1s # 获取每条信息的时间间隔
    done
}
running_flag=1 # 1标志程序运行中，-1标志退出程序
while [ $running_flag -eq 1 ]
do
    flash_fans_info
    sleep 1h
done