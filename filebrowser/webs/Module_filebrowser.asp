<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache" />
<meta http-equiv="Expires" content="-1" />
<link rel="shortcut icon" href="/res/icon-filebrowser.png" />
<link rel="icon" href="/res/icon-filebrowser.png" />
<title>软件中心 - FileBrowser</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<link rel="stylesheet" type="text/css" href="usp_style.css">
<link rel="stylesheet" type="text/css" href="css/element.css">
<link rel="stylesheet" type="text/css" href="/device-map/device-map.css">
<link rel="stylesheet" type="text/css" href="/js/table/table.css">
<link rel="stylesheet" type="text/css" href="/res/layer/theme/default/layer.css">
<link rel="stylesheet" type="text/css" href="/res/softcenter.css">
<script language="JavaScript" type="text/javascript" src="/js/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/httpApi.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/js/table/table.js"></script>
<script language="JavaScript" type="text/javascript" src="/res/softcenter.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/switcherplugin/jquery.iphone-switch.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<style>
a:focus {
	outline: none;
}
.SimpleNote {
	padding:5px 5px;
}
i {
    color: #FC0;
    font-style: normal;
} 
.loadingBarBlock{
	width:740px;
}
.popup_bar_bg_ks{
	position:fixed;
	margin: auto;
	top: 0;
	left: 0;
	width:100%;
	height:100%;
	z-index:99;
	/*background-color: #444F53;*/
	filter:alpha(opacity=90);  /*IE5、IE5.5、IE6、IE7*/
	background-repeat: repeat;
	visibility:hidden;
	overflow:hidden;
	/*background: url(/images/New_ui/login_bg.png);*/
	background:rgba(68, 79, 83, 0.85) none repeat scroll 0 0 !important;
	background-position: 0 0;
	background-size: cover;
	opacity: .94;
}

.FormTitle em {
    color: #00ffe4;
    font-style: normal;
    /*font-weight:bold;*/
}
.FormTable th {
	width: 30%;
}
.formfonttitle {
	font-family: Roboto-Light, "Microsoft JhengHei";
	font-size: 18px;
	margin-left: 5px;
}
.FormTitle, .FormTable, .FormTable th, .FormTable td, .FormTable thead td, .FormTable_table, .FormTable_table th, .FormTable_table td, .FormTable_table thead td {
	font-size: 14px;
	font-family: Roboto-Light, "Microsoft JhengHei";
}
.content_status {
	position: absolute;
	-webkit-border-radius: 5px;
	-moz-border-radius: 5px;
	border-radius:10px;
	z-index: 10;
	margin-left: -215px;
	top: 0;
	left: 0;
	height:auto;
	box-shadow: 3px 3px 10px #000;
	background: rgba(0,0,0,0.88);
	width:748px;
	/*display:none;*/
	visibility:hidden;
}
.user_title{
	text-align:center;
	font-size:18px;
	color:#99FF00;
	padding:10px;
	font-weight:bold;
}
.contentM_qis {
	position: absolute;
	-webkit-border-radius: 5px;
	-moz-border-radius: 5px;
	border-radius: 5px;
	z-index: 200;
	background-color:#2B373B;
	margin-left: 10px;
	top: 250px;
	width:730px;
	return height:auto;
	box-shadow: 3px 3px 10px #000;
	/*display:none;*/
	line-height:1.8;
	visibility:hidden;
}
.pop_div_bg{
	background-color: #2B373B; /* W3C asuscss */
}
.QISform_wireless {
	width:690px;
	font-size:14px;
	color:#FFFFFF;
}
#fb_db_settings_div,{
	border: none; /* W3C asuscss */
}
</style>
<script type="text/javascript">
var dbus = {};
var refresh_flag
var db_fb = {}
var count_down;
var _responseLen;
var STATUS_FLAG;
var noChange = 0;
var params_check = ['filebrowser_https', 'filebrowser_publicswitch', 'filebrowser_watchdog'];
var params_input = ['filebrowser_cert_file', 'filebrowser_key_file', 'filebrowser_port'];

String.prototype.myReplace = function(f, e){
	var reg = new RegExp(f, "g"); 
	return this.replace(reg, e); 
}

function init() {
	show_menu(menu_hook);
	register_event();
	get_dbus_data();
	check_status();
}

function get_dbus_data(){
	$.ajax({
		type: "GET",
		url: "/_api/filebrowser_",
		dataType: "json",
		async: false,
		success: function(data) {
			dbus = data.result[0];
			conf2obj();
			show_hide_element();
			pannel_access();
		}
	});
}

function pannel_access(){
	if(dbus["filebrowser_enable"] == "1"){
		//var protocol = location.protocol;
		if(E("filebrowser_publicswitch").checked){
			if(E("filebrowser_https").checked){
				protocol = "https:";
			}else{
				protocol ="http:";
			}
		}else{
			protocol ="http:";
		}

		var hostname = document.domain;
		if (hostname.indexOf('.kooldns.cn') != -1 || hostname.indexOf('.ddnsto.com') != -1 || hostname.indexOf('.tocmcc.cn') != -1) {
			protocol = location.protocol;//如果是走的ddnsto则不管是否开启公网开关。
			if(hostname.indexOf('.kooldns.cn') != -1){
				hostname = hostname.replace('.kooldns.cn','-fb.kooldns.cn');
			}else if(hostname.indexOf('.ddnsto.com') != -1){
				hostname = hostname.replace('.ddnsto.com','-fb.ddnsto.com');
			}else{
				hostname = hostname.replace('.tocmcc.cn','-fb.tocmcc.cn');
			}

			webUiHref = protocol + "//" + hostname;
		}else{
			webUiHref = protocol + "//" + location.hostname + ":" + dbus["filebrowser_port"];
		}

		E("fileb").href = webUiHref;
		E("fileb").innerHTML = "访问 Filebrowser";
	}
}

function conf2obj(){
	for (var i = 0; i < params_check.length; i++) {
		if(dbus[params_check[i]]){
			E(params_check[i]).checked = dbus[params_check[i]] != "0";
		}
	}
	for (var i = 0; i < params_input.length; i++) {
		if (dbus[params_input[i]]) {
			$("#" + params_input[i]).val(dbus[params_input[i]]);
		}
	}
	if (dbus["fb_version"]){
		E("fb_version").innerHTML = " - " + dbus["fb_version"];
	}
}

function show_hide_element(){
	if(dbus["filebrowser_enable"] == "1"){
		E("fb_status").style.display = "";
		E("fb_pannel").style.display = "";
		E("fb_db").style.display = "";
		E("fb_apply_1").style.display = "none";
		E("fb_apply_2").style.display = "";
		E("fb_apply_3").style.display = "";
	}else{
		E("fb_status").style.display = "";
		E("fb_pannel").style.display = "none";
		E("fb_db").style.display = "none";
		E("fb_apply_1").style.display = "";
		E("fb_apply_2").style.display = "none";
		E("fb_apply_3").style.display = "none";
	}

	// CERT/KEY ERROR
	if(dbus["filebrowser_cert_error"] == "1"){
		$("#filebrowser_cert_file").css({
			"border": "1px solid #fc0410",
			"color": "#fc0410"
		});
	}
	if(dbus["filebrowser_key_error"] == "1"){
		$("#filebrowser_key_file").css({
			"border": "1px solid #fc0410",
			"color": "#fc0410"
		});
	}

	if(dbus["filebrowser_cert_error"] == "1" && dbus["filebrowser_key_error"] == "1"){
		E("warn_cert").innerHTML = "【下方证书公钥Cert文件 + 证书私钥Key文件配置错误，无法启用https！详见插件日志】";
	}else if (dbus["filebrowser_cert_error"] == "1" && dbus["filebrowser_key_error"] != "1"){
		E("warn_cert").innerHTML = "【下方证书公钥Cert文件配置错误，无法启用https！详见插件日志】";
	}else if (dbus["filebrowser_cert_error"] != "1" && dbus["filebrowser_key_error"] == "1"){
		E("warn_cert").innerHTML = "【下方证书私钥Key文件配置错误，无法启用https！详见插件日志】";
	}

	// SHOW HIDE
	if(E("filebrowser_publicswitch").checked == false){
		E("fb_https").style.display = "none";
		E("fb_cert").style.display = "none";
		E("fb_key").style.display = "none";
	}else{
		E("fb_https").style.display = "";
		if(E("filebrowser_https").checked == false){
			E("fb_cert").style.display = "none";
			E("fb_key").style.display = "none";
		}else{
			E("fb_cert").style.display = "";
			E("fb_key").style.display = "";
		} 
	}
}

function menu_hook(title, tab) {
	tabtitle[tabtitle.length - 1] = new Array("", "filebrowser");
	tablink[tablink.length - 1] = new Array("", "Module_filebrowser.asp");
}

function register_event(){
	$(".popup_bar_bg_ks").click(
		function() {
			count_down = -1;
		});
	$(window).resize(function(){
		var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
		var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
		if($('.popup_bar_bg_ks').css("visibility") == "visible"){
			document.scrollingElement.scrollTop = 0;
			var log_h = E("loadingBarBlock").clientHeight;
			var log_w = E("loadingBarBlock").clientWidth;
			var log_h_offset = (page_h - log_h) / 2;
			var log_w_offset = (page_w - log_w) / 2 + 90;
			$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
		}
	});
}

function check_status(){
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "filebrowser_config.sh", "params":['status'], "fields": ""};
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		data: JSON.stringify(postData),
		success: function (response) {
			E("filebrowser_status").innerHTML = response.result;
			setTimeout("check_status();", 10000);
		},
		error: function(){
			E("filebrowser_status").innerHTML = "获取运行状态失败";
			setTimeout("check_status();", 5000);
		}
	});
}

function save(flag){
	var db_fb = {};
	if(flag){
		console.log(flag)
		db_fb["filebrowser_enable"] = flag;
	}else{
		db_fb["filebrowser_enable"] = "0";
	}
	for (var i = 0; i < params_check.length; i++) {
			db_fb[params_check[i]] = E(params_check[i]).checked ? '1' : '0';
	}
	for (var i = 0; i < params_input.length; i++) {
		if (E(params_input[i])) {
			db_fb[params_input[i]] = E(params_input[i]).value;
		}
	} 
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "filebrowser_config.sh", "params": ["web_submit"], "fields": db_fb};
	$.ajax({
		type: "POST",
		url: "/_api/",
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response) {
			if(response.result == id){
				get_log();
			}
		}
	});
}

function get_log(flag){
	E("ok_button").style.visibility = "hidden";
	showALLoadingBar();
	$.ajax({
		url: '/_temp/filebrowser_log.txt',
		type: 'GET',
		cache:false,
		dataType: 'text',
		success: function(response) {
			var retArea = E("log_content");
			if (response.search("XU6J03M6") != -1) {
				retArea.value = response.myReplace("XU6J03M6", " ");
				E("ok_button").style.visibility = "visible";
				retArea.scrollTop = retArea.scrollHeight;
				if(flag == 1){
					count_down = -1;
					refresh_flag = 0;
				}else{
					count_down = 6;
					refresh_flag = 1;
				}
				count_down_close();
				return false;
			}
			setTimeout("get_log(" + flag + ");", 500);
			retArea.value = response.myReplace("XU6J03M6", " ");
			retArea.scrollTop = retArea.scrollHeight;
		},
		error: function(xhr) {
			E("loading_block_title").innerHTML = "暂无日志信息 ...";
			E("log_content").value = "日志文件为空，请关闭本窗口！";
			E("ok_button").style.visibility = "visible";
			return false;
		}
	});
}

function showALLoadingBar(){
	document.scrollingElement.scrollTop = 0;
	E("loading_block_title").innerHTML = "&nbsp;&nbsp;filebrowser日志信息";
	E("LoadingBar").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var log_h = E("loadingBarBlock").clientHeight;
	var log_w = E("loadingBarBlock").clientWidth;
	var log_h_offset = (page_h - log_h) / 2;
	var log_w_offset = (page_w - log_w) / 2 + 90;
	$('#loadingBarBlock').offset({top: log_h_offset, left: log_w_offset});
}
function hideALLoadingBar(){
	E("LoadingBar").style.visibility = "hidden";
	E("ok_button").style.visibility = "hidden";
	if (refresh_flag == "1"){
		refreshpage();
	}
}
function count_down_close() {
	if (count_down == "0") {
		hideALLoadingBar();
	}
	if (count_down < 0) {
		E("ok_button1").value = "手动关闭"
		return false;
	}
	E("ok_button1").value = "自动关闭（" + count_down + "）"
		--count_down;
	setTimeout("count_down_close();", 1000);
}
function database_mission() {
	$('body').prepend(tableApi.genFullScreen());
	$('.fullScreen').show();
	document.scrollingElement.scrollTop = 0;
	E("fb_db_settings").style.visibility = "visible";
	var page_h = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;
	var page_w = window.innerWidth || document.documentElement.clientWidth || document.body.clientWidth;
	var fb_h = E("fb_db_settings").clientHeight;
	var fb_w = E("fb_db_settings").clientWidth;
	var fb_h_offset = (page_h - fb_h) / 2 - 90;
	var fb_w_offset = (page_w - fb_w) / 2 + 90;
	if(fb_h_offset < 0){
		fb_h_offset = 10;
	}
	$('#fb_db_settings').offset({top: fb_h_offset, left: fb_w_offset});
}
function close_db_sett() {
	E("fb_db_settings").style.visibility = "hidden";
	$("body").find(".fullScreen").fadeOut(300, function() { tableApi.removeElement("fullScreen"); });
}
function down_database() {
	var id = parseInt(Math.random() * 100000000);
	var postData = {"id": id, "method": "filebrowser_config.sh", "params":["download_db"], "fields": "" };
	$.ajax({
		type: "POST",
		url: "/_api/",
		async: true,
		cache:false,
		data: JSON.stringify(postData),
		dataType: "json",
		success: function(response){
			if(response.result == id){
				get_log();
				var a = document.createElement('A');
				a.href = "_root/files/filebrowser.db";
				a.download = 'filebrowser.db';
				document.body.appendChild(a);
				a.click();
				document.body.removeChild(a);
				count_down = -1;
			}
		}
	});	
}

function upload_database() {
	var filename = $("#database").val();
	filename = filename.split('\\');
	filename = filename[filename.length - 1];
	var filelast = filename.split('.');
	filelast = filelast[filelast.length - 1];
	if (filelast != "db") {
		alert('上传文件格式非法！只支持上传db后缀的数据库文件');
		return false;
	}
	E('file_info').style.display = "none";
	var formData = new FormData();
	var dbname = "filebrowser.db";
	formData.append(dbname, document.getElementById('database').files[0]);

	$.ajax({
		url: '/_upload',
		type: 'POST',
		cache: false,
		data: formData,
		processData: false,
		contentType: false,
		complete: function(res) {
			if (res.status == 200) {
				upload_data(dbname);
			}
		}
	});
}
function upload_data(dbname) {
	var id = parseInt(Math.random() * 100000000);
	db_fb = {};
	db_fb["filebrowser_upload_db"] = dbname;
	var postData = { "id": id, "method": "filebrowser_config.sh", "params": ["upload_db"], "fields": db_fb };
	$.ajax({
		url: "/_api/",
		cache: false,
		type: "POST",
		dataType: "json",
		data: JSON.stringify(postData),
		success: function(response){
			if(response.result == id){
				get_log();
				E('file_info').style.display = "block";   
			}
		}
	});    
}
</script>
</head>
<body id="app" skin='<% nvram_get("sc_skin"); %>' onload="init();">
	<div id="TopBanner"></div>
	<div id="Loading" class="popup_bg"></div>
	<div id="LoadingBar" class="popup_bar_bg_ks" style="z-index: 201;" >
		<table cellpadding="5" cellspacing="0" id="loadingBarBlock" class="loadingBarBlock" align="center">
			<tr>
				<td height="100">
					<div id="loading_block_title" style="margin:10px auto;margin-left:10px;width:85%; font-size:12pt;"></div>
					<div id="loading_block_spilt" style="margin:10px 0 10px 5px;" class="loading_block_spilt">
						<li><font color="#ffcc00">请等待日志显示完毕，并出现自动关闭按钮！</font></li>
						<li><font color="#ffcc00">在此期间请不要刷新本页面，不然可能导致问题！</font></li>
					</div>
					<div style="margin-left:15px;margin-right:15px;margin-top:10px;outline: 1px solid #3c3c3c;overflow:hidden">
						<textarea cols="50" rows="25" wrap="off" readonly="readonly" id="log_content" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" style="border:1px solid #000;width:99%; font-family:'Lucida Console'; font-size:11px;background:transparent;color:#FFFFFF;outline: none;padding-left:5px;padding-right:22px;overflow-x:hidden"></textarea>
					</div>
					<div id="ok_button" class="apply_gen" style="background:#000;visibility:hidden;">
						<input id="ok_button1" class="button_gen" type="button" onclick="hideALLoadingBar()" value="确定">
					</div>
				</td>
			</tr>
		</table>
	</div>
	<!--============================this is the popup area for db========================================-->
	<div id="fb_db_settings" class="contentM_qis pop_div_bg">
		<table class="QISform_wireless" border="0" align="center" cellpadding="5" cellspacing="0">
			<tr>
				<td>
					<div class="user_title">FileBrowser 数据库备份/回复</div>
					<div id="fb_db_settings_div">
						<table id="table_edit" style="margin:-1px 0px 0px 0px;" width="100%" border="1" align="center" cellpadding="4" cellspacing="0" class="FormTable">
							<thead>
								<tr>
									<td colspan="2">filebrowser database</td>
								</tr>
							</thead>
							<tr>
								<th>备份数据库</th>
								<td>
									<a type="button" class="ks_btn" style="cursor: pointer; display: inline;" onclick="down_database()">备份数据库</a>
								</td>
							</tr>
							<tr>
								<th>恢复数据库</th>
								<td>
									<a class="ks_btn" href="javascript:void(0);" onclick="upload_database()" style="display: inline;">恢复数据库</a>
									<input style="color:#FFCC00;*color:#000;width: 260px;vertical-align: middle;" id="database" type="file" name="file">
									<img id="loadingicon" style="margin-left:5px;margin-right:5px;display:none;" src="/images/InternetScan.gif">
									<span id="file_info" style="display:none;">完成</span>
								</td>
							</tr>
						</table>
					</div>
				</td>
			</tr>
		</table>
		<span style="margin-left:30px">1. filebrowser数据库储存了filebrowser的一些重要设置，比如启动参数，用户账户密码及其目录，证书配置等等信息。</span>
		<span style="margin-left:30px">2. 你也可以使用filebrowser自己的文件下载功能，下载<i>/koolshare/configs/filebrowser/filebrowser.db</i>文件，实现备份。</span>
		<div style="padding-top:10px;padding-bottom:10px;width:100%;text-align:center;">
			<input class="button_gen" type="button" onclick="close_db_sett();" id="cancelBtn" value="返回">
		</div>
	</div>
	<iframe name="hidden_frame" id="hidden_frame" width="0" height="0" frameborder="0"></iframe>
	<!--=============================================================================================================-->
	<table class="content" align="center" cellpadding="0" cellspacing="0">
		<tr>
			<td width="17">&nbsp;</td>
			<td valign="top" width="202">
				<div id="mainMenu"></div>
				<div id="subMenu"></div>
			</td>
			<td valign="top">
				<div id="tabMenu" class="submenuBlock"></div>
				<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
					<tr>
						<td align="left" valign="top">
							<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
								<tr>
									<td bgcolor="#4D595D" colspan="3" valign="top">
										<div>&nbsp;</div>
										<div class="formfonttitle">FileBrowser <lable id="fb_version"></lable></div>
										<div style="float: right; width: 15px; height: 25px; margin-top: -20px">
											<img id="return_btn" alt="" onclick="reload_Soft_Center();" align="right" style="cursor: pointer; position: absolute; margin-left: -30px; margin-top: -25px;" title="返回软件中心" src="/images/backprev.png" onmouseover="this.src='/images/backprevclick.png'" onmouseout="this.src='/images/backprev.png'" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div class="SimpleNote">
											<a href="https://github.com/filebrowser/filebrowser" target="_blank"><em>FileBrowser</em></a>可以在指定目录内提供文件管理，且能创建多个用户，每个用户拥有自己的目录。
											<span><a type="button" href="https://github.com/flyhigherpi/filebrowser" target="_blank" class="ks_btn" style="margin-left:5px;" >项目地址</a></span>
											<span><a type="button" class="ks_btn" href="javascript:void(0);" onclick="get_log(1)" style="margin-left:5px;">插件日志</a></span>
										</div>
										<div id="filebrowser_status_pannel">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">filebrowser - 状态</td>
													</tr>
												</thead>
												<tr id="fb_status" style="display: none;">
													<th>状态</th>
													<td>
														<span style="margin-left:4px" id="filebrowser_status"></span>
													</td>
												</tr>
												<tr id="fb_pannel" style="display: none;">
													<th>访问</th>
													<td>
														<a type="button" style="vertical-align:middle;cursor:pointer;" id="fileb" class="ks_btn" href="" target="_blank">访问 Filebrowser</a>
													</td>
												</tr>
											</table>
										</div>
										<div style="margin-top:10px">
											<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable">
												<thead>
													<tr>
														<td colspan="2">Filebrowser - 设置</td>
													</tr>
												</thead>
												<tr>
													<th>实时进程守护</th>
													<td>
														<input type="checkbox" id="filebrowser_watchdog" style="vertical-align:middle;">
													</td>
												</tr>
												<tr>
													<th>开启公网访问</th>
													<td>
														<input type="checkbox" id="filebrowser_publicswitch" onchange="show_hide_element();" style="vertical-align:middle;">
													</td>
												</tr>
												<tr id="fb_db">
													<th>备份/恢复数据库</th>
													<td>
														<a type="button" style="vertical-align: middle; cursor:pointer;" class="ks_btn" onclick="database_mission()">备份/恢复数据库</a>
													</td>
												</tr>
												<tr id="fb_port">
													<th>面板端口</th>
													<td>
														<input type="text" id="filebrowser_port" style="width: 50px;" maxlength="5" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="26789">
													</td>
												</tr>
												<tr id="fb_https">
													<th>启用https</th>
													<td>
														<input type="checkbox" id="filebrowser_https" onchange="show_hide_element();" style="vertical-align:middle;" />
														<span id="warn_cert" style="color:red;margin-left:5px;vertical-align:middle;font-size:11px;"><span>
													</td>
												</tr>
												<tr id="fb_cert">
													<th>证书公钥Cert文件 (绝对路径)</th>
													<td>
													<input type="text" id="filebrowser_cert_file" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="/tmp/etc/cert.pem">
													</td>
												</tr>
												<tr id="fb_key">
													<th>证书私钥Key文件 (绝对路径)</th>
													<td>
													<input type="text" id="filebrowser_key_file" style="width: 95%;" class="input_3_table" autocorrect="off" autocapitalize="off" style="background-color: rgb(89, 110, 116);" value="" placeholder="/tmp/etc/key.pem">
													</td>
												</tr>
											</table>
										</div>
										<div id="fb_apply" class="apply_gen">
											<input class="button_gen" style="display: none;" id="fb_apply_1" onClick="save(1)" type="button" value="开启" />
											<input class="button_gen" style="display: none;" id="fb_apply_2" onClick="save(2)" type="button" value="重启" />
											<input class="button_gen" style="display: none;" id="fb_apply_3" onClick="save(0)" type="button" value="关闭" />
										</div>
										<div style="margin: 10px 0 10px 5px;" class="splitLine"></div>
										<div style="margin:10px 0 0 5px">
											<li>FileBRowser的初始用户名和密码均为：<em>admin</em>，请及时修改，以避免公网访问开启后的安全问题。</li>
											<li>登陆后可在【Setting】-【Profile Settings】中修改语言为中文。</li>
										</div>
									</td>
								</tr>
							</table>
						</td>
					</tr>
				</table>
			</td>
			<td width="10" align="center" valign="top"></td>
		</tr>
	</table>
	<div id="footer"></div>
</body>
</html>
