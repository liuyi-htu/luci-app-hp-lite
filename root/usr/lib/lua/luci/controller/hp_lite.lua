module("luci.controller.hp_lite", package.seeall)

local SAVE_PATH = "/usr/bin/hp-litec"
local UPLOAD_TMP = "/tmp/hp-litec.upload"
local SERVER_SAVE_PATH = "/usr/bin/hp-lites"
local SERVER_UPLOAD_TMP = "/tmp/hp-lites.upload"
local DEFAULT_LOG_DIR = "/var/log/hp-lite"
local DEFAULT_CLIENT_LOG_FILE = DEFAULT_LOG_DIR .. "/hp-litec.log"
local DEFAULT_SERVER_LOG_FILE = DEFAULT_LOG_DIR .. "/hp-lites.log"
local i18n_ok, i18n = pcall(require, "luci.i18n")

local function tr(key, fallback)
    local msgid = "hp-lite." .. key
    local text = i18n_ok and i18n and i18n.translate and i18n.translate(msgid) or msgid
    return text ~= msgid and text or fallback
end

local function is_hp_lite_installed(fs, sys)
    if fs.access(SAVE_PATH, "x") then
        return true
    end
    return sys.call("command -v hp-litec >/dev/null 2>&1") == 0
end

local function is_hp_lites_installed(fs)
    return fs.access(SERVER_SAVE_PATH, "x")
end

local function write_upload_json(http, ok, message)
    http.prepare_content("application/json")
    http.write_json({ ok = ok, message = message })
end

local function receive_upload(http, fs, tmp_path)
    local fp
    local upload_error
    os.remove(tmp_path)

    http.setfilehandler(function(meta, chunk, eof)
        if meta and meta.name == "file" and meta.file and not fp and not upload_error then
            fp, upload_error = io.open(tmp_path, "w")
        end

        if fp and chunk then
            fp:write(chunk)
        end

        if fp and eof then
            fp:close()
            fp = nil
        end
    end)

    http.formvalue("file")

    if fp then
        fp:close()
    end

    local stat = fs.stat(tmp_path)
    if upload_error or not stat or stat.size == 0 then
        os.remove(tmp_path)
        return false
    end

    return true
end

local title_client_config = tr("client_configuration", "Client Configuration")
local title_client_log = tr("client_runtime_log", "Client Runtime Log")
local title_server_config = tr("server_configuration", "Server Configuration")
local title_server_log = tr("server_runtime_log", "Server Runtime Log")
local app_title = tr("app_title", "hp-lite")

function index()
    local nixio = require "nixio"
    if not nixio.fs.access("/etc/config/hp-litec") and not nixio.fs.access("/etc/config/hp-lites") then
        return
    end

    entry({"admin", "services", "hp-lite"}, firstchild(), app_title, 60).dependent = true
    entry({"admin", "services", "hp-lite", "config"}, cbi("hp_lite/config"), title_client_config, 1).leaf = true
    entry({"admin", "services", "hp-lite", "log"}, view("hp_lite/log"), title_client_log, 2).leaf = true
    entry({"admin", "services", "hp-lite", "server"}, cbi("hp_lite/server"), title_server_config, 3).leaf = true
    entry({"admin", "services", "hp-lite", "server_log"}, view("hp_lite/log"), title_server_log, 4).leaf = true
    entry({"admin", "services", "hp-lite", "action"}, call("action_service")).leaf = true
    entry({"admin", "services", "hp-lite", "upload"}, call("upload_binary")).leaf = true
    entry({"admin", "services", "hp-lite", "upload_server"}, call("upload_server_binary")).leaf = true
    entry({"admin", "services", "hp-lite", "get_client_log"}, call("get_client_log")).leaf = true
    entry({"admin", "services", "hp-lite", "get_server_log"}, call("get_server_log")).leaf = true
    entry({"admin", "services", "hp-lite", "get_client_status"}, call("get_client_status")).leaf = true
    entry({"admin", "services", "hp-lite", "get_server_status"}, call("get_server_status")).leaf = true
    entry({"admin", "services", "hp-lite", "get_log"}, call("get_log")).leaf = true
end

function action_service()
    local http = require "luci.http"
    local util = require "luci.util"

    local act = http.formvalue("act")
    local cmd = ""

    if act == "start" then
        cmd = "/etc/init.d/hp-litec start"
    elseif act == "stop" then
        cmd = "/etc/init.d/hp-litec stop"
    elseif act == "restart" then
        cmd = "/etc/init.d/hp-litec restart"
    end

    if #cmd > 0 then
        util.exec(cmd .. " >/dev/null 2>&1")
    end

    http.prepare_content("application/json")
    http.write_json({ status = "ok", action = act })
end

function upload_binary()
    local http = require "luci.http"
    local sys = require "luci.sys"
    local fs = require "nixio.fs"

    if not receive_upload(http, fs, UPLOAD_TMP) then
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end

    if is_hp_lite_installed(fs, sys) then
        sys.call("/etc/init.d/hp-litec stop >/dev/null 2>&1")
    end

    if sys.call("mv -f " .. UPLOAD_TMP .. " " .. SAVE_PATH .. " >/dev/null 2>&1") ~= 0 then
        os.remove(UPLOAD_TMP)
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end

    if sys.call("chmod +x " .. SAVE_PATH .. " >/dev/null 2>&1") ~= 0 then
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end
    if sys.call("[ -x /etc/init.d/hp-litec ]") == 0 then
        sys.call("/etc/init.d/hp-litec enable >/dev/null 2>&1")
    end
    sys.call("/etc/init.d/hp-litec restart >/dev/null 2>&1")

    write_upload_json(http, true, tr("uploaded_and_installed_successfully", "Uploaded and installed successfully"))
end

function upload_server_binary()
    local http = require "luci.http"
    local sys = require "luci.sys"
    local fs = require "nixio.fs"

    if not receive_upload(http, fs, SERVER_UPLOAD_TMP) then
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end

    if is_hp_lites_installed(fs) then
        sys.call("/etc/init.d/hp-lites stop >/dev/null 2>&1")
    end

    if sys.call("mv -f " .. SERVER_UPLOAD_TMP .. " " .. SERVER_SAVE_PATH .. " >/dev/null 2>&1") ~= 0 then
        os.remove(SERVER_UPLOAD_TMP)
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end

    if sys.call("chmod +x " .. SERVER_SAVE_PATH .. " >/dev/null 2>&1") ~= 0 then
        write_upload_json(http, false, tr("upload_failed", "Upload failed"))
        return
    end
    if sys.call("[ -x /etc/init.d/hp-lites ]") == 0 then
        sys.call("/etc/init.d/hp-lites write_config >/dev/null 2>&1")
        sys.call("/etc/init.d/hp-lites enable >/dev/null 2>&1")
        sys.call("/etc/init.d/hp-lites restart >/dev/null 2>&1")
    end

    write_upload_json(http, true, tr("uploaded_and_installed_successfully", "Uploaded and installed successfully"))
end

local function normalize_log_dir(value)
    local dir = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if dir == "" or not dir:match("^/") or dir:find("..", 1, true) then
        dir = DEFAULT_LOG_DIR
    end
    while dir ~= "/" and dir:sub(-1) == "/" do
        dir = dir:sub(1, -2)
    end
    return dir
end

local function normalize_log_file(value, default_file)
    local file = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if file == "" or not file:match("^/") or file:find("..", 1, true) or file:sub(-1) == "/" then
        file = default_file
    end
    return file
end

local function log_file(config, section, default_file, legacy_filename)
    local uci = require "luci.model.uci".cursor()
    local file = uci:get(config, section, "log_file")
    if not file or file == "" then
        local dir = normalize_log_dir(uci:get(config, section, "log_dir"))
        file = dir .. "/" .. legacy_filename
    end
    return normalize_log_file(file, default_file)
end

local function write_log(logfile)
    local max_lines = 300
    local content = ""
    local readable = false

    local f = io.open(logfile, "r")
    if f then
        local lines = {}
        for line in f:lines() do
            table.insert(lines, line)
            if #lines > max_lines then table.remove(lines, 1) end
        end
        content = table.concat(lines, "\n")
        f:close()
        readable = true
    end

    local http = require "luci.http"
    http.prepare_content("application/json")
    http.write_json({ log = content, readable = readable, file = logfile })
end

function get_client_log()
    write_log(log_file("hp-litec", "global", DEFAULT_CLIENT_LOG_FILE, "hp-litec.log"))
end

function get_server_log()
    write_log(log_file("hp-lites", "server", DEFAULT_SERVER_LOG_FILE, "hp-lites.log"))
end

function get_log()
    get_client_log()
end

local function write_status(running)
    local http = require "luci.http"
    http.prepare_content("application/json")
    http.write_json({ running = running })
end

function get_client_status()
    local sys = require "luci.sys"
    write_status(sys.call("pidof hp-litec >/dev/null 2>&1") == 0)
end

function get_server_status()
    local sys = require "luci.sys"
    write_status(sys.call("pidof hp-lites >/dev/null 2>&1") == 0)
end
