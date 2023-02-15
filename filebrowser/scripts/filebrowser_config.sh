#!/bin/sh

source /koolshare/scripts/base.sh
eval $(dbus export filebrowser_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
LOG_FILE=/tmp/upload/filebrowser_log.txt
FB_LOG_FILE=/tmp/upload/filebrowser.log
dbfile_save=/koolshare/configs/filebrowser/filebrowser.db
dbfile_curr=/tmp/fb/filebrowser.db
LOCK_FILE=/var/lock/filebrowser.lock
BASH=${0##*/}
ARGS=$@

set_lock(){
	exec 233>${LOCK_FILE}
	flock -n 233 || {
		# bring back to original log
		http_response "$ACTION"
		exit 1
	}
}

unset_lock(){
	flock -u 233
	rm -rf ${LOCK_FILE}
}

number_test(){
	case $1 in
		''|*[!0-9]*)
			echo 1
			;;
		*)
			echo 0
			;;
	esac
}

detect_running_status(){
	local BINNAME=$1
	local PID
	local i=40
	until [ -n "${PID}" ]; do
		usleep 250000
		i=$(($i - 1))
		PID=$(pidof ${BINNAME})
		if [ "$i" -lt 1 ]; then
			echo_date "🔴$1进程启动失败，请检查你的配置！"
			return
		fi
	done
	echo_date "🟢$1启动成功，pid：${PID}"
}

check_usb2jffs_used_status(){
	# 查看当前/jffs的挂载点是什么设备，如/dev/mtdblock9, /dev/sda1；有usb2jffs的时候，/dev/sda1，无usb2jffs的时候，/dev/mtdblock9，出问题未正确挂载的时候，为空
	local cur_patition=$(df -h | /bin/grep /jffs | awk '{print $1}')
	local jffs_device="not mount"
	if [ -n "${cur_patition}" ];then
  		jffs_device=${cur_patition}
  fi
	local mounted_nu=$(mount | /bin/grep "${jffs_device}" | grep -E "/tmp/mnt/|/jffs"|/bin/grep -c "/dev/s")
	if [ "${mounted_nu}" -eq "2" ]; then
    echo "1" #已安装并成功挂载
  else
  	echo "0" #未安装或未挂载
  fi
}

write_backup_job(){
	sed -i '/filebrowser_backupdb/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	echo_date "ℹ️创建数据库备份任务" >> $LOG_FILE
	cru a filebrowser_backupdb  "*/1 * * * * /bin/sh /koolshare/scripts/filebrowser_config.sh backup"
}

kill_cron_job() {
	if [ -n "$(cru l | grep filebrowser_backupdb)" ]; then
		echo_date "ℹ️删除filebrowser数据库备份任务..."
		sed -i '/filebrowser_backupdb/d' /var/spool/cron/crontabs/* >/dev/null 2>&1
	fi
}

restore_used_db(){
	# sync db
	if [ -f "${dbfile_curr}" ];then
		cp -rf ${dbfile_curr} ${dbfile_save}
    echo_date "⚠️ 复制FileBrowser数据库至备份目录！"
		if [ "$?" == "0" ];then
			rm -rf /tmp/fb
		fi
	fi
  kill_cron_job
}

check_run_mode(){
  if [ $(check_usb2jffs_used_status) == "1" ] && [ ${1} == "start" ];then
      echo_date "➡️检测到已安装插件usb2jffs并成功挂载，插件可以正常启动！"
      restore_used_db
  fi
}

checkDbFilePath() {
  local ACT=${1}
  check_run_mode ${ACT}
	#检查db运行目录是放在/tmp还是/koolshare
	if [ "${ACT}" = "start" ];then
	  if [ $(check_usb2jffs_used_status) != "1" ]; then #未挂载usb2jffs就检测是否需要运行在/tmp目录
      local configRunTmp='0'
      local LINUX_VER=$(uname -r|awk -F"." '{print $1$2}')
      if [ "$LINUX_VER" = 41 ]; then #内核过低就运行在Tmp目录
        echo_date "⚠️检测到内核版本过低，设置FileBrowser为Tmp目录模式！"
        configRunTmp="1"
      fi
      if [ ${configRunTmp} == "1" ]; then
	      export FB_DATABASE=${dbfile_curr}
        echo_date "⚠️[Tmp目录模式] FileBrowser将运行在/tmp目录！"
        echo_date "⚠️安装usb2jffs插件并成功挂载可恢复正常运行模式！"
        if [ -f "${dbfile_save}" ];then
          echo_date "➡️[Tmp目录模式] 复制FileBrowser数据库至使用目录！"
        	cp -rf ${dbfile_save} ${dbfile_curr}
        fi
        write_backup_job
      fi
    fi
  else
    restore_used_db
	fi
}

check_status(){
	local FB_PID=$(pidof filebrowser)
	if [ "${filebrowser_enable}" == "1" ]; then
		if [ -n "${FB_PID}" ]; then
			if [ "${filebrowser_watchdog}" == "1" ]; then
				local filebrowser_time=$(perpls|grep filebrowser|grep -Eo "uptime.+-s\ " | awk -F" |:|/" '{print $3}')
				if [ -n "${filebrowser_time}" ]; then
					local ret="filebrowser 进程运行正常！（PID：${FB_PID} , 守护运行时间：${filebrowser_time}）"
				else
					local ret="filebrowser 进程运行正常！（PID：${FB_PID}）"
				fi
			else
				local ret="filebrowser 进程运行正常！（PID：${FB_PID}）"
			fi
		else
			local ret="filebrowser 进程未运行！"
		fi
	else
		local ret="filebrowser 插件未启用"
	fi
	http_response "$ret"
}

check_memory(){
	local swap_size=$(free | grep Swap | awk '{print $2}');
	if [ "$swap_size" != "0" ];then
		echo_date "✅️当前系统已经启用虚拟内存！容量：${swap_size}KB"
	else
		local memory_size=$(free | grep Mem | awk '{print $2}');
		if [ "$memory_size" != "0" ];then
			if [  $memory_size -le 750000 ];then
				echo_date "❌️插件启动异常！"
				echo_date "❌️检测到系统内存为：${memory_size}KB，需挂载虚拟内存！"
				echo_date "❌️filebrowser程序对路由器开销较大，需要挂载1G及以上虚拟内存后重新启动插件！"
				close_fb_process
				dbus set filebrowser_memory_error=1
				dbus set filebrowser_enable=0
				exit
			else
				echo_date "⚠️filebrowser程序对路由器开销较大，建议挂载1G及以上虚拟内存，以保证稳定！"
				dbus set filebrowser_memory_warn=1
			fi
		else
			echo_date"⚠️未查询到系统内存，请自行注意系统内存！"
		fi
	fi
}

close_fb_process(){
	fb_process=$(pidof filebrowser)
	if [ -n "${fb_process}" ]; then
		echo_date "⛔关闭filebrowser进程..."
		if [ -f "/koolshare/perp/filebrowser/rc.main" ]; then
			perpctl d filebrowser >/dev/null 2>&1
		fi
		rm -rf /koolshare/perp/filebrowser
		killall filebrowser >/dev/null 2>&1
		kill -9 "${fb_process}" >/dev/null 2>&1
	fi
  # check is  run in /tmp dir
  checkDbFilePath stop
}

start_fb_process(){
	rm -rf ${FB_LOG_FILE}
	if [ "${filebrowser_watchdog}" == "1" ]; then
		echo_date "🟠启动 filebrowser 进程，开启进程实时守护..."
		mkdir -p /koolshare/perp/filebrowser
		cat >/koolshare/perp/filebrowser/rc.main <<-EOF
			#!/bin/sh
			/koolshare/scripts/base.sh
			export FB_PORT=${FB_PORT}
			export FB_ADDRESS=${FB_ADDRESS}
			export FB_ROOT="/"
			export FB_DATABASE=${FB_DATABASE}
			export FB_CERT=${FB_CERT}
			export FB_KEY=${FB_KEY}
			export FB_LOG=${FB_LOG}
			if test \${1} = 'start' ; then
				exec filebrowser
			fi
			exit 0

		EOF
		chmod +x /koolshare/perp/filebrowser/rc.main
		chmod +t /koolshare/perp/filebrowser/
		sync
		perpctl A filebrowser >/dev/null 2>&1
		perpctl u filebrowser >/dev/null 2>&1
		detect_running_status filebrowser
	else
		echo_date "🟠启动 filebrowser 进程..."
		rm -rf /tmp/filebrowser.pid
		start-stop-daemon -S -q -b -m -p /tmp/var/filebrowser.pid -x /koolshare/bin/filebrowser
		sleep 2
		detect_running_status filebrowser
	fi
}

check_config(){
	lan_ipaddr=$(ifconfig br0|grep -Eo "inet addr.+"|awk -F ":| " '{print $3}' 2>/dev/null)
	mkdir -p /koolshare/configs/filebrowser
	mkdir -p /tmp/fb

	dbfile_save=/koolshare/configs/filebrowser/filebrowser.db
	dbfile_curr=/tmp/fb/filebrowser.db

	export FB_DATABASE=${dbfile_save}
	export FB_ROOT="/"
	export FB_LOG=${FB_LOG_FILE}

	#check is need run in /tmp dir
  checkDbFilePath start

	if [ $(number_test ${filebrowser_port}) != "0" ]; then
		export FB_PORT=26789
		dbus set filebrowser_port=26789
	else
		export FB_PORT=${filebrowser_port}
	fi

	if [ "${filebrowser_publicswitch}" == "1" ];then
		export FB_ADDRESS="0.0.0.0"
	else
		export FB_ADDRESS=${lan_ipaddr}
	fi

	if [ "${filebrowser_publicswitch}" == "1" ]; then
		if [ "${filebrowser_https}" == "1" ]; then
			# 1. https开关要打开
			if [ -n "${filebrowser_cert_file}" -a -n "${filebrowser_key_file}" ]; then
				# 2. 证书文件路径和密钥文件路径都不能为空
				if [ -f "${filebrowser_cert_file}" -a -f "${filebrowser_key_file}" ]; then
					# 3. 证书文件和密钥文件要在路由器内找得到
					local CER_VERFY=$(openssl x509 -noout -pubkey -in ${filebrowser_cert_file} 2>/dev/null)
					local KEY_VERFY=$(openssl pkey -pubout -in ${filebrowser_key_file} 2>/dev/null)
					if [ -n "${CER_VERFY}" -a -n "${KEY_VERFY}" ]; then
						# 4. 证书文件和密钥文件要是合法的
						local CER_MD5=$(echo "${CER_VERFY}" | md5sum | awk '{print $1}')
						local KEY_MD5=$(echo "${KEY_VERFY}" | md5sum | awk '{print $1}')
						if [ "${CER_MD5}" == "${KEY_MD5}" ]; then
							# 5. 证书文件和密钥文件还必须得相匹配
							echo_date "🆗证书校验通过！为filebrowser面板启用https..."
							export FB_CERT=${filebrowser_cert_file}
							export FB_KEY=${filebrowser_key_file}
						else
							echo_date "⚠️无法启用https，原因如下："
							echo_date "⚠️证书公钥:${filebrowser_cert_file} 和证书私钥: ${filebrowser_key_file}不匹配！"
							dbus set filebrowser_cert_error=1
							dbus set filebrowser_key_error=1
						fi
					else
						echo_date "⚠️无法启用https，原因如下："
						if [ -z "${CER_VERFY}" ]; then
							echo_date "⚠️证书公钥Cert文件错误，检测到这不是公钥文件！"
							dbus set filebrowser_cert_error=1
						fi
						if [ -z "${KEY_VERFY}" ]; then
							echo_date "⚠️证书私钥Key文件错误，检测到这不是私钥文件！"
							dbus set filebrowser_key_error=1
						fi
					fi
				else
					echo_date "⚠️无法启用https，原因如下："
					if [ ! -f "${filebrowser_cert_file}" ]; then
						echo_date "⚠️未找到证书公钥Cert文件！"
						dbus set filebrowser_cert_error=1
					fi
					if [ ! -f "${filebrowser_key_file}" ]; then
						echo_date "⚠️未找到证书私钥Key文件！"
						dbus set filebrowser_key_error=1
					fi
				fi
			else
				echo_date "⚠️无法启用https，原因如下："
				if [ -z "${filebrowser_cert_file}" ]; then
					echo_date "⚠️证书公钥Cert文件路径未配置！"
					dbus set filebrowser_cert_error=1
				fi
				if [ -z "${filebrowser_key_file}" ]; then
					echo_date "⚠️证书私钥Key文件路径未配置！"
					dbus set filebrowser_key_error=1
				fi
			fi
		fi
	fi
}

open_port() {
	local CM=$(lsmod | grep xt_comment)
	local OS=$(uname -r)
	if [ -z "${CM}" -a -f "/lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko" ];then
		echo_date "ℹ️加载xt_comment.ko内核模块！"
		insmod /lib/modules/${OS}/kernel/net/netfilter/xt_comment.ko
	fi

	local MATCH=$(iptables -t filter -S INPUT | grep "fb_rule")
	if [ -z "${MATCH}" ];then
		echo_date "🧱添加防火墙入站规则，打开filebrowser端口：${FB_PORT}"
		iptables -I INPUT -p tcp --dport ${FB_PORT} -j ACCEPT -m comment --comment "fb_rule" >/dev/null 2>&1
	fi
}

close_port(){
	local IPTS=$(iptables -t filter -S | grep -w "fb_rule" | sed 's/-A/iptables -t filter -D/g')
	if [ -n "${IPTS}" ];then
		echo_date "🧱关闭本插件在防火墙上打开的所有端口!"
		iptables -t filter -S | grep -w "fb_rule" | sed 's/-A/iptables -t filter -D/g' > /tmp/clean.sh
		chmod +x /tmp/clean.sh
		sh /tmp/clean.sh > /dev/null 2>&1
		rm /tmp/clean.sh
	fi
}

start_backup(){
	mkdir -p /koolshare/configs/
	if [ -f "${dbfile_curr}" ]; then
		if [ ! -f "${dbfile_save}" ]; then
		    cp -rf ${dbpath_tmp} ${dbfile_save}
		    logger "[${0##*/}]：备份filebrowser数据库!"
		else
			local new=$(md5sum ${dbfile_curr} | awk '{print $1}')
			local old=$(md5sum ${dbfile_save} | awk '{print $1}')
			if [ "${new}" != "${old}" ] ; then
			    cp -rf ${dbfile_curr} ${dbfile_save}
			    logger "[${0##*/}]：filebrowser 数据库变化，备份数据库!"
			fi
		fi
	fi
}

close_fb(){
	# 1. remove log
	rf -rf ${FB_LOG_FILE}

	# 2. stop fb
	close_fb_process

	# 3. close_port
	close_port
}

start_fb (){
	# 1. check_memory
	check_memory

	# 2. stop first
	close_fb_process

	# 3. check_config
	check_config

	# 4. start process
	start_fb_process

	# 5. open port
	if [ "${filebrowser_publicswitch}" == "1" ];then
		close_port >/dev/null 2>&1
		open_port
	fi
}

upload_database(){
	if [ -f "/tmp/upload/${filebrowser_upload_db}" ]; then
		echo_date "ℹ️检测到上传的数据库文件！"
		echo_date "ℹ️执行数据库还原工作"
		close_fb_process
		mkdir -p /koolshare/configs/filebrowser
		rm -rf /tmp/${filebrowser_upload_db}
		mv -f /tmp/upload/${filebrowser_upload_db} ${dbfile_save}
		if [ "${filebrowser_enable}" == "1" ]; then
			start_fb
		fi
	else
		echo_date "❌没找到数据库文件，不执行任何操作!"
		rm -rf /tmp/upload/*.db
	fi
}

download_database(){
	echo_date "定位文件"
	rm -rf /tmp/files
	rm -rf /koolshare/webs/files
	mkdir -p /tmp/files
	ln -sf /tmp/files /koolshare/webs/files

	tmp_path=/tmp/files

	if [ -f "${dbfile_curr}" ];then
		cp -rf ${dbfile_curr} /tmp/files/filebrowser.db
	else
		if [ -f "${dbfile_save}" ];then
			cp -rf ${dbfile_save} /tmp/files/filebrowser.db
		else
			http_response "fail" >/dev/null 2>&1
		fi
	fi

	if [ -f /tmp/files/filebrowser.db ]; then
		echo_date "文件已复制"
		http_response "$ID" >/dev/null 2>&1
		sleep 3
		rm -rf /tmp/files/filebrowser.db
	else
		http_response "fail" >/dev/null 2>&1
		echo_date "文件复制失败"
	fi
}

case $1 in
start)
	if [ "${filebrowser_enable}" == "1" ]; then
		logger "[软件中心-开机自启]: filebrowser自启动开启！"
		start_fb
	else
		logger "[软件中心-开机自启]: filebrowser未开启，不自动启动！"
	fi
	;;
boot_up)
	if [ "${filebrowser_enable}" == "1" ]; then
		start_fb
	fi
	;;
start_nat)
	if [ "${filebrowser_enable}" == "1" ]; then
		logger "[软件中心]-[${0##*/}]: NAT重启触发打开filebrowser防火墙端口！"
		if [ $(number_test ${filebrowser_port}) != "0" ]; then
			FB_PORT=26789
			dbus set filebrowser_port=26789
		else
			FB_PORT=${filebrowser_port}
		fi
		close_port
		open_port
	fi
	;;
backup)
	start_backup
	;;
stop)
	close_fb
	;;
esac

case $2 in
web_submit)
	set_lock
	true > ${LOG_FILE}
	http_response "$1"
	# 调试
	# echo_date "$BASH $ARGS" | tee -a ${LOG_FILE}
	# echo_date filebrowser_enable=${filebrowser_enable} | tee -a ${LOG_FILE}
	if [ "${filebrowser_enable}" == "1" ]; then
		echo_date "▶️开启filebrowser！" | tee -a ${LOG_FILE}
		start_fb | tee -a ${LOG_FILE}
	elif [ "${filebrowser_enable}" == "2" ]; then
		echo_date "🔁重启filebrowser！" | tee -a ${LOG_FILE}
		dbus set filebrowser_enable=1
		start_fb | tee -a ${LOG_FILE}
	else
		echo_date "ℹ️停止filebrowser！" | tee -a ${LOG_FILE}
		close_fb | tee -a ${LOG_FILE}
	fi
	echo XU6J03M6 | tee -a ${LOG_FILE}
	unset_lock
	;;
status)
	check_status
	;;
download_db)
	true > ${LOG_FILE}
	download_database | tee -a ${LOG_FILE}
	echo XU6J03M6 | tee -a ${LOG_FILE}
	;;
upload_db)
	true > ${LOG_FILE}
	http_response "$1"
	upload_database | tee -a ${LOG_FILE}
	echo XU6J03M6 | tee -a ${LOG_FILE}
	;;
esac
