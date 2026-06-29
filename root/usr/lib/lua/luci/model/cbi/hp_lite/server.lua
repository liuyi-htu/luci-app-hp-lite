local util = require "luci.util"
local sys = require "luci.sys"
local nixio = require "nixio"
local dispatcher = require "luci.dispatcher"
local uci = require "luci.model.uci".cursor()

local server_save_path = "/usr/bin/hp-lites"

local function ensure_server_section()
    if uci:get_all("hp-lites", "server") then
        return
    end

    uci:section("hp-lites", "hp-lites", "server", {
        log_file = "/var/log/hp-lite/hp-lites.log",
        log_retention_days = "3"
    })
    uci:commit("hp-lites")
end

ensure_server_section()

local function tr(key, fallback)
    local msgid = "hp-lite." .. key
    local text = translate(msgid)
    return text ~= msgid and text or fallback
end

local m = Map("hp-lites", "")

local s = m:section(NamedSection, "server", "hp-lites", "")

local running = (sys.call("pidof hp-lites >/dev/null 2>&1") == 0)
local status = s:option(DummyValue, "_status", tr("running_status", "Running Status"))
status.rawhtml = true
if running then
    status.value = string.format("<b style='color:green'>%s</b>", tr("running", "running"))
else
    status.value = string.format("<b style='color:red'>%s</b>", tr("stopped", "stoped"))
end

local start_btn = s:option(Button, "_start", tr("start_service", "Start Service"))
start_btn.inputstyle = "apply"
function start_btn.write()
    util.exec("/etc/init.d/hp-lites start >/dev/null 2>&1")
    luci.http.redirect(dispatcher.build_url("admin/services/hp-lite/server"))
end

local stop_btn = s:option(Button, "_stop", tr("stop_service", "Stop Service"))
stop_btn.inputstyle = "reset"
function stop_btn.write()
    util.exec("/etc/init.d/hp-lites stop >/dev/null 2>&1")
    luci.http.redirect(dispatcher.build_url("admin/services/hp-lite/server"))
end

local clear_btn = s:option(Button, "_clear", tr("clear_log", "Clear Log"))
clear_btn.inputstyle = "danger"
function clear_btn.write()
    util.exec("/etc/init.d/hp-lites clear_log >/dev/null 2>&1")
end

local admin_username = s:option(Value, "admin_username", tr("admin_username", "Admin Username"))
admin_username.placeholder = "zyh"
admin_username.rmempty = true

local admin_password = s:option(Value, "admin_password", tr("admin_password", "Admin Password"))
admin_password.placeholder = "123456"
admin_password.password = true
admin_password.rmempty = true

local admin_port = s:option(Value, "admin_port", tr("admin_port", "Admin Port"))
admin_port.placeholder = "9090"
admin_port.datatype = "port"
admin_port.rmempty = true

local cmd_port = s:option(Value, "cmd_port", tr("command_port", "Command Port"))
cmd_port.placeholder = "16666"
cmd_port.datatype = "port"
cmd_port.rmempty = true

local tunnel_ip = s:option(Value, "tunnel_ip", tr("tunnel_ip", "Tunnel IP/Domain"))
tunnel_ip.placeholder = "127.0.0.1"
tunnel_ip.rmempty = true

local tunnel_port = s:option(Value, "tunnel_port", tr("tunnel_port", "Tunnel Port"))
tunnel_port.placeholder = "9091"
tunnel_port.datatype = "port"
tunnel_port.rmempty = true

local open_domain = s:option(Flag, "open_domain", tr("open_domain", "Open Domain Forwarding"))
open_domain.default = "0"
open_domain.rmempty = true

local acme_email = s:option(Value, "acme_email", tr("acme_email", "ACME Email"))
acme_email.placeholder = "1540187368@qq.com"
acme_email.rmempty = true

local acme_http_port = s:option(Value, "acme_http_port", tr("acme_http_port", "ACME HTTP Port"))
acme_http_port.placeholder = "5634"
acme_http_port.datatype = "port"
acme_http_port.rmempty = true

local log_file = s:option(Value, "log_file", tr("log_file", "Log File"))
log_file.default = "/var/log/hp-lite/hp-lites.log"
log_file.placeholder = "/var/log/hp-lite/hp-lites.log"
log_file.rmempty = false
function log_file.validate(self, value, section)
    value = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if value == "" or not value:match("^/") or value:find("..", 1, true) or value:sub(-1) == "/" then
        return nil, tr("invalid_log_file", "Log file must be an absolute file path and must not contain ..")
    end
    return value
end

local retention = s:option(Value, "log_retention_days", tr("log_retention_days", "Log Retention Days"))
retention.default = "3"
retention.placeholder = "3"
retention.datatype = "range(1,3650)"
retention.rmempty = false

local function html_escape(value)
    return tostring(value or "")
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function is_hp_lites_installed()
    return server_save_path and nixio.fs.access(server_save_path, "x")
end

local install_status = s:option(DummyValue, "_install_status", tr("install_status", "Install Status"))
install_status.rawhtml = true
if is_hp_lites_installed() then
    local version = sys.exec(server_save_path .. " -v 2>/dev/null | head -n1")
    if version and version ~= "" then
        install_status.value = string.format(
            "<span style='color:green'>%s</span><br/><small>%s %s</small>",
            tr("installed", "Installed"),
            tr("version_label", "Version:"),
            html_escape(version)
        )
    else
        install_status.value = string.format("<span style='color:green'>%s</span>", tr("installed", "Installed"))
    end
else
    install_status.value = string.format("<span style='color:red'>%s</span>", tr("not_installed", "Not installed"))
end

local remove_btn = s:option(Button, "_remove_installed", tr("remove_installed", "Remove Installed"))
remove_btn.inputstyle = "remove"
function remove_btn.write()
    util.exec("/etc/init.d/hp-lites stop >/dev/null 2>&1")
    util.exec("/etc/init.d/hp-lites disable >/dev/null 2>&1")
    util.exec("rm -f /usr/bin/hp-lites /tmp/hp-lites.upload >/dev/null 2>&1")
    m.message = tr("removed_successfully", "Removed successfully")
    luci.http.redirect(dispatcher.build_url("admin/services/hp-lite/server"))
end

local upload_url = dispatcher.build_url("admin/services/hp-lite/upload_server")
local page_url = dispatcher.build_url("admin/services/hp-lite/server")
local token = dispatcher.context and dispatcher.context.authtoken or ""
if token ~= "" then
    upload_url = upload_url .. "?token=" .. token
end

local upload = s:option(DummyValue, "_local_upload", tr("local_upload", "Local Upload"))
upload.rawhtml = true
upload.value = string.format([[
<div style="margin-bottom:6px;font-size:12px;line-height:1.4">
    <span style="color:red;font-weight:bold">%s</span><span>%s</span>
</div>
<div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
    <input type="file" id="hp-lites-upload-file" style="display:none" />
    <button type="button" id="hp-lites-file-button" class="cbi-button">%s</button>
    <span id="hp-lites-file-name" style="min-width:120px">%s</span>
    <button type="button" id="hp-lites-upload-button" class="cbi-button cbi-button-apply">%s</button>
    <span id="hp-lites-upload-message" style="font-size:12px"></span>
</div>
<script type="text/javascript">
(function() {
    var file = document.getElementById("hp-lites-upload-file");
    var fileButton = document.getElementById("hp-lites-file-button");
    var fileName = document.getElementById("hp-lites-file-name");
    var button = document.getElementById("hp-lites-upload-button");
    var message = document.getElementById("hp-lites-upload-message");
    var uploadUrl = %q;
    var pageUrl = %q;
    var token = %q;
    var chooseText = %q;
    var uploadingText = %q;
    var requestFailedText = %q;
    var noFileChosenText = %q;

    function updateFileName() {
        if (!fileName) {
            return;
        }

        fileName.textContent = file && file.files && file.files.length
            ? file.files[0].name
            : noFileChosenText;
    }

    function show(text, color) {
        if (!message) {
            return;
        }
        message.textContent = text || "";
        message.style.color = color || "";
    }

    if (fileButton && file) {
        fileButton.onclick = function() {
            file.click();
        };
    }

    if (file) {
        file.onchange = updateFileName;
        updateFileName();
    }

    if (!button) {
        return;
    }

    button.onclick = function() {
        if (!file || !file.files || file.files.length === 0) {
            show(chooseText, "#b56b00");
            return;
        }

        if (typeof FormData === "undefined") {
            show(requestFailedText, "#c00");
            return;
        }

        var data = new FormData();
        data.append("token", token);
        data.append("file", file.files[0]);

        button.disabled = true;
        show(uploadingText, "");

        var xhr = new XMLHttpRequest();
        xhr.open("POST", uploadUrl, true);
        xhr.onreadystatechange = function() {
            var res = null;

            if (xhr.readyState !== 4) {
                return;
            }

            button.disabled = false;

            try {
                res = JSON.parse(xhr.responseText || "{}");
            } catch (e) {}

            if (xhr.status >= 200 && xhr.status < 300 && res && res.ok) {
                show(res.message || "", "green");
                window.setTimeout(function() {
                    window.location.href = pageUrl;
                }, 800);
            } else {
                show((res && res.message) || requestFailedText, "#c00");
            }
        };
        xhr.onerror = function() {
            button.disabled = false;
            show(requestFailedText, "#c00");
        };
        xhr.send(data);
    };
})();
</script>
]], "！！！", html_escape(tr("server_upload_space_warning", "Server binary files are large. Please make sure your router has enough storage space first.")),
    html_escape(tr("choose_file", "Choose File")),
    html_escape(tr("no_file_chosen", "No file chosen")),
    html_escape(tr("local_upload", "Local Upload")),
    upload_url, page_url, token,
    tr("choose_file_first", "Please choose a file first."),
    tr("uploading", "Uploading..."),
    tr("upload_request_failed", "Upload request failed"),
    tr("no_file_chosen", "No file chosen"))

function m.on_after_apply(self, map)
    util.exec("uci commit hp-lites")
    util.exec("/etc/init.d/hp-lites write_config >/dev/null 2>&1")
end

return m
