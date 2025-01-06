#!/system/bin/sh

function boot(){
while true;
do
btcplt=$(getprop vendor.oplus.boot_complete)
if [ "$btcplt" -eq "1" ];then
	return 0
fi
sleep 1
done
}

boot

# 初始化包名文件和日志文件
PACKAGE_FILE="/data/adb/modules/auto_cpucloser/packages.txt"
LOG_FILE="/data/local/tmp/cpu_manager.log"

# CPU 开核和关核的函数
enable_all_cores() {
    echo 1 > /sys/devices/system/cpu/cpu6/online
    echo 1 > /sys/devices/system/cpu/cpu7/online
#    echo "$(date): Enabled CPU cores" >> /data/local/tmp/cpu_manager.log
}

disable_extra_cores() {
    echo 0 > /sys/devices/system/cpu/cpu6/online
    echo 0 > /sys/devices/system/cpu/cpu7/online
#    echo "$(date): Disabled CPU cores" >> /data/local/tmp/cpu_manager.log
}

# 确保包名文件存在
#if [ ! -f "$PACKAGE_FILE" ]; then
#    echo "$(date): Package file not found!" >> "$LOG_FILE"
#    sleep 2
#    continue
#fi

# 读取包名列表
package_names=""
while read -r app; do
	package_names=$package_names$app" "
done < "$PACKAGE_FILE"

disable_extra_cores

last_state=true
# 主循环
while true; do
    # 获取当前前台应用包名
    current_app=$(dumpsys activity activities | grep "topResumedActivity=" | tail -n 1 | cut -d '{' -f2 | cut -d '/' -f1 | cut -d ' ' -f3)

    # 检测是否有可见包名
    is_target_visible=false
    for app in $package_names
	do
		if [ "$current_app" = "$app" ]; then
			is_target_visible=true
		fi
	done

    # 根据检测结果执行逻辑
    if [ "$is_target_visible" = true ]; then
        if [ "$last_state" != false ]; then
            last_state=false
            enable_all_cores
        fi
    else
        if [ "$last_state" = false ]; then
            last_state=true
            disable_extra_cores
        fi
    fi

    # 每 2 秒检查一次
    sleep 2
done