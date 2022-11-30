#!/bin/sh
eval $(dbus export filebrowser_)
source /koolshare/scripts/base.sh

if [ "$filebrowser_enable" == "1" ];then
	echo_date 先关闭filebrowser插件！
	sh /koolshare/scripts/filebrowser_start.sh stop
fi

find /koolshare/init.d/ -name "*filebrowser*" | xargs rm -rf
rm -rf /koolshare/bin/filebrowser 2>/dev/null
rm -rf /tmp/filebrowser 2>/dev/null
rm -rf /koolshare/res/icon-filebrowser.png 2>/dev/null
rm -rf /koolshare/scripts/filebrowser*.sh 2>/dev/null
rm -rf /koolshare/webs/Module_filebrowser.asp 2>/dev/null
rm -rf /koolshare/scripts/filebrowser_install.sh 2>/dev/null
rm -rf /koolshare/scripts/uninstall_filebrowser.sh 2>/dev/null
rm -rf /koolshare/configs/filebrowser 2>/dev/null
rm -rf /tmp/upload/filebrowser* 2>/dev/null

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