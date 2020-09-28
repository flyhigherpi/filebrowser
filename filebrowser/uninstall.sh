#!/bin/sh
eval `dbus export filebrowser_`
source /koolshare/scripts/base.sh


if [ "$filebrowser_enable" == "1" ];then
	echo_date 关闭filebrowser插件！
	sh /koolshare/scripts/filebrowser_start.sh stop
    sleep 1
fi


find /koolshare/init.d/ -name "*filebrowser*" | xargs rm -rf

rm -rf /koolshare/bin/filebrowser
rm -rf /koolshare/bin/filebrowser.db
rm -rf /tmp/bin/filebrowser
rm -rf /tmp/bin/filebrowser.db
rm -rf /tmp/filebrowser.log
rm -rf /koolshare/res/icon-filebrowser.png
rm -rf /koolshare/scripts/filebrowser*.sh
rm -rf /koolshare/webs/Module_filebrowser.asp
rm -rf /koolshare/scripts/filebrowser_install.sh
rm -rf /koolshare/scripts/uninstall_filebrowser.sh

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