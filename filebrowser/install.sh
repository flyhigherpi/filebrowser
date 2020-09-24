#! /bin/sh

# shadowsocks script for HND/AXHND router with kernel 4.1.27/4.1.51 merlin firmware

source /koolshare/scripts/base.sh
eval $(dbus export filebrowser_)
alias echo_date='echo 【$(TZ=UTC-8 date -R +%Y年%m月%d日\ %X)】:'
MODEL=$(nvram get productid)

sleep 2s

# 获取固件类型
_get_type() {
	local FWTYPE=$(nvram get extendno|grep koolshare)
	if [ -d "/koolshare" ];then
		if [ -n $FWTYPE ];then
			echo "koolshare官改固件"
		else
			echo "koolshare梅林改版固件"
		fi
	else
		if [ "$(uname -o|grep Merlin)" ];then
			echo "梅林原版固件"
		else
			echo "华硕官方固件"
		fi
	fi
}

exit_install(){
	local state=$1
	case $state in
		1)
			echo_date "本插件适用于适用于【koolshare 梅林改/官改 hnd/axhnd/axhnd.675x】固件平台，你的固件平台不能安装！！！"
			echo_date "本插件支持机型/平台：https://github.com/koolshare/rogsoft#rogsoft"
			echo_date "退出安装！"
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 1
			;;
		0|*)
			rm -rf /tmp/${module}* >/dev/null 2>&1
			exit 0
			;;
	esac
}

# 判断路由架构和平台
case $(uname -m) in
	aarch64)
		if [ "$(uname -o|grep Merlin)" -a -d "/koolshare" ];then
			echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
		else
			exit_install 1
		fi
		;;
	#armv7l)
	#	if [ "$MODEL" == "TUF-AX3000" -o "$MODEL" == "RT-AX82U" ] && [ -d "/koolshare" ];then
	#		echo_date 机型：$MODEL $(_get_type) 符合安装要求，开始安装插件！
	#	else
	#		exit_install 1
	#	fi
	#	;;
	*)
		exit_install 1
	;;
esac


ROG_86U=0
EXT_NU=$(nvram get extendno)
EXT_NU=${EXT_NU%_*}

if [ -n "$(nvram get extendno | grep koolshare)" -a "$(nvram get productid)" == "RT-AC86U" -a "${EXT_NU}" -lt "81918" ];then
	ROG_86U=1
fi

# 判断固件需要什么UI
if [ "$MODEL" == "GT-AC5300" -o "$MODEL" == "GT-AX11000" -o "$ROG_86U" == "1" ];then
	# 官改固件，骚红皮肤
	ROG=1
fi

#if [ "$MODEL" == "TUF-AX3000" ];then
	# 官改固件，橙色皮肤
#	TUF=1
#fi

filebrowser_pid=$(pidof filebrowser)
if [ -n "filebrowser_pid" ];then
	echo_date 先关闭filebrowser，保证文件更新成功!
	[ -f "/koolshare/scripts/filebrowser_start.sh" ] && sh /koolshare/scripts/filebrowser_start.sh stop
fi


# 检测储存空间是否足够
echo_date 检测jffs分区剩余空间...
SPACE_AVAL=$(df|grep jffs | awk '{print $4}')
SPACE_NEED=$(du -s /tmp/filebrowser | awk '{print $1}')
if [ "$SPACE_AVAL" -gt "$SPACE_NEED" ];then
	echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装需要"$SPACE_NEED" KB，空间满足，继续安装！
	#
	echo_date 清理旧文件
	rm -rf /koolshare/scripts/filebrowser_start.sh
	rm -rf /koolshare/scripts/filebrowser_status.sh
	rm -rf /koolshare/webs/Module_filebrowser*
	rm -rf /koolshare/res/icon-filebrowser.png
	rm -rf /koolshare/bin/filebrowser
	rm -rf /koolshare/bin/filebrowser.db
	rm -rf /tmp/bin/filebrowser
	rm -rf /tmp/bin/filebrowser.db
	rm -rf /tmp/filebrowser.log
	find /koolshare/init.d/ -name "*filebrowser.sh" | xargs rm -rf

	echo_date 开始复制文件！
	cd /tmp

	echo_date 复制相关二进制文件！此步时间可能较长！
	cp -rf /tmp/filebrowser/bin/filebrowser /koolshare/bin/

	echo_date 复制相关的脚本文件！
	cp -rf /tmp/filebrowser/scripts/* /koolshare/scripts/
	cp -rf /tmp/filebrowser/install.sh /koolshare/scripts/filebrowser_install.sh
	cp -rf /tmp/filebrowser/uninstall.sh /koolshare/scripts/uninstall_filebrowser.sh

	echo_date 复制相关的网页文件！
	cp -rf /tmp/filebrowser/webs/* /koolshare/webs/
	cp -rf /tmp/filebrowser/res/* /koolshare/res/

	echo_date 为新安装文件赋予执行权限...
	chmod 755 /koolshare/scripts/filebrowser*
	chmod 755 /koolshare/bin/filebrowser

	echo_date 创建一些二进制文件的软链接！
	[ ! -L "/koolshare/init.d/S99filebrowser.sh" ] && ln -sf /koolshare/scripts/filebrowser_start.sh /koolshare/init.d/S99filebrowser.sh
	
	# 离线安装时设置软件中心内储存的版本号和连接
	echo_date 清除冗余数据
	dbus remove filebrowser_version_local
	dbus remove filebrowser_watchdog
	dbus remove filebrowser_port
	dbus remove filebrowser_publicswitch
	dbus remove filebrowser_delay_time
	dbus remove filebrowser_uploaddatabase
	dbus remove softcenter_module_filebrowser_install
	dbus remove softcenter_module_filebrowser_version
	dbus remove softcenter_module_filebrowser_title
	dbus remove softcenter_module_filebrowser_description
	echo_date 设置初始值
	CUR_VERSION=$(cat /tmp/filebrowser/version)
	dbus set filebrowser_version_local="$CUR_VERSION"
	dbus set softcenter_module_filebrowser_install="1"
	dbus set softcenter_module_filebrowser_version="$CUR_VERSION"
	dbus set softcenter_module_filebrowser_title="FileBrowser"
	dbus set softcenter_module_filebrowser_description="FileBrowser：您的可视化路由文件管理系统"

	echo_date 一点点清理工作...
	rm -rf /tmp/filebrowser* >/dev/null 2>&1

	echo_date filebrowser插件安装成功！
	

	echo_date 更新完毕，请等待网页自动刷新！
else
	echo_date 当前jffs分区剩余"$SPACE_AVAL" KB, 插件安装需要"$SPACE_NEED" KB，空间不足！
	echo_date 退出安装！
	exit 1
fi