'use strict';
'require view';
'require poll';
'require dom';

return view.extend({
    render: function() {
        function hpTranslate(key, fallback) {
            var msgid = 'hp-lite.' + key;
            var text = _(msgid);
            return text !== msgid ? text : fallback;
        }

        var tabScrollStyle = E('style', {'id':'hp-lite-tab-scroll-style'}, [
'@media screen and (max-width: 768px) {\n' +
'  .tabs,\n' +
'  .tabs > ul,\n' +
'  ul.tabs,\n' +
'  .cbi-tabmenu {\n' +
'    display: flex !important;\n' +
'    flex-wrap: nowrap !important;\n' +
'    overflow-x: auto !important;\n' +
'    overflow-y: hidden !important;\n' +
'    white-space: nowrap !important;\n' +
'    -webkit-overflow-scrolling: touch;\n' +
'    scrollbar-width: thin;\n' +
'  }\n' +
'\n' +
'  .tabs > li,\n' +
'  .tabs > ul > li,\n' +
'  ul.tabs > li,\n' +
'  .cbi-tabmenu > li {\n' +
'    flex: 0 0 auto !important;\n' +
'    float: none !important;\n' +
'    white-space: nowrap !important;\n' +
'  }\n' +
'\n' +
'  .tabs > li > a,\n' +
'  .tabs > ul > li > a,\n' +
'  ul.tabs > li > a,\n' +
'  .cbi-tabmenu > li > a {\n' +
'    display: block !important;\n' +
'    white-space: nowrap !important;\n' +
'  }\n' +
'}\n'
        ]);

        var statusLine = E('div', {
            'id': 'hp-lite-running-status',
            'style': 'margin:0 0 22px 0;'
        });

        var pageHeader = E('div', {'id':'hp-lite-page-header', 'style':'margin:0 0 12px 0'}, [
            E('h1', {'style':'font-size:24px;line-height:1.2;margin:0 0 14px 0;font-weight:700'}, ['hp-lite 内网穿透']),
            statusLine
        ]);

        function moveHpLiteHeader() {
            var header = document.getElementById('hp-lite-page-header');
            var tabs = document.querySelector('.tabs, ul.tabs, .cbi-tabmenu');
            if (!header || !tabs || !tabs.parentNode) {
                return;
            }
            if (tabs.previousElementSibling !== header) {
                tabs.parentNode.insertBefore(header, tabs);
            }
        }

        window.setTimeout(moveHpLiteHeader, 0);
        window.setTimeout(moveHpLiteHeader, 100);
        window.setTimeout(moveHpLiteHeader, 500);

        var log_box = E('div', {'id':'log_box'});
        var logEndpoint = '/cgi-bin/luci/admin/services/hp-lite/get_client_log';

        function makePre(text) {
            return E('pre', {
                'style': 'white-space: pre-wrap; font-size:12px; background:#f7f7f7; padding:10px; border-radius:8px; border:1px solid #ccc;'
            }, [text]);
        }

        function statusSpan(text) {
            return E('span', {
                'style': 'font-size:13px;font-weight:bold;font-style:italic;color:green;white-space:nowrap;'
            }, [text]);
        }

        function renderRunningStatus(clientRunning, serverRunning) {
            var nodes = [];

            if (clientRunning) {
                nodes.push(statusSpan('hp-lite 客户端 ' + hpTranslate('running', 'running')));
            }

            if (serverRunning) {
                if (nodes.length > 0) {
                    nodes.push('\u00a0\u00a0\u00a0\u00a0');
                }
                nodes.push(statusSpan('hp-lite 服务端 ' + hpTranslate('running', 'running')));
            }

            dom.content(statusLine, nodes);
            statusLine.style.display = nodes.length ? '' : 'none';
        }

        function refreshStatus() {
            Promise.all([
                fetch('/cgi-bin/luci/admin/services/hp-lite/get_client_status').then(r => r.json()).catch(() => ({running:false})),
                fetch('/cgi-bin/luci/admin/services/hp-lite/get_server_status').then(r => r.json()).catch(() => ({running:false}))
            ]).then(results => {
                renderRunningStatus(!!(results[0] && results[0].running), !!(results[1] && results[1].running));
            });
        }

        dom.content(log_box, makePre(hpTranslate('loading_client_log', 'Loading client log...')));

        function refreshLog() {
            fetch(logEndpoint)
                .then(r => r.json())
                .then(res => {
                    var text = res.readable === false
                        ? hpTranslate('cannot_read_client_log_file', 'Cannot read client log file.')
                        : (res.log || hpTranslate('client_log_empty', 'Client log is empty.'));

                    text = '[Client Log]\n' + text;

                    dom.content(log_box, makePre(text));
                    log_box.scrollTop = log_box.scrollHeight;
                })
                .catch(() => {
                    dom.content(log_box, makePre(hpTranslate('cannot_read_client_log_file', 'Cannot read client log file.')));
                });
        }

        poll.add(L.bind(function() {
            refreshStatus();
            refreshLog();
        }));
        refreshStatus();
        refreshLog();

        var customText1 = E('div', {
            'style': 'margin-bottom:10px; padding:8px; background:#f0f8ff; border-radius:4px; font-size:13px;'
        }, hpTranslate('credit_text', 'This client was made by zhangyahao from HTU.'));

        return E([], [
            tabScrollStyle,
            pageHeader,
            customText1,
            log_box,
            E('div', {'style':'text-align:right;font-size:12px; margin-top:5px;'}, hpTranslate('refresh_interval', 'Refresh every %s seconds.').format(L.env.pollinterval))
        ]);
    }
});
