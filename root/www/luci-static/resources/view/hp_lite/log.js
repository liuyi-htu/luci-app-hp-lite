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

        var log_box = E('div', {'id':'log_box'});
        var isServerLog = window.location.pathname.indexOf('/server_log') !== -1;
        var logEndpoint = isServerLog
            ? '/cgi-bin/luci/admin/services/hp-lite/get_server_log'
            : '/cgi-bin/luci/admin/services/hp-lite/get_client_log';
        function makePre(text) {
            return E('pre', {
                'style': 'white-space: pre-wrap; font-size:12px; background:#f7f7f7; padding:10px; border-radius:8px; border:1px solid #ccc;'
            }, [text]);
        }

        dom.content(log_box, makePre(hpTranslate('loading_log', 'Loading log...')));

        function refreshLog() {
            fetch(logEndpoint)
                .then(r => r.json())
                .then(res => {
                    var text = res.readable === false
                        ? hpTranslate('cannot_read_log_file', 'Cannot read log file.')
                        : (res.log || hpTranslate('log_empty', 'Log is empty.'));
                    dom.content(log_box, makePre(text));
                    log_box.scrollTop = log_box.scrollHeight;
                })
                .catch(() => {
                    dom.content(log_box, makePre(hpTranslate('cannot_read_log_file', 'Cannot read log file.')));
                });
        }

        poll.add(L.bind(function() {
            refreshLog();
        }));
        refreshLog();

        var creditKey = isServerLog ? 'server_credit_text' : 'credit_text';
        var creditFallback = isServerLog
            ? 'This server was made by zhangyahao from HTU.'
            : 'This client was made by zhangyahao from HTU.';
        var customText1 = E('div', {
            'style': 'margin-bottom:10px; padding:8px; background:#f0f8ff; border-radius:4px; font-size:13px;'
        }, hpTranslate(creditKey, creditFallback));
        return E([], [
            customText1,
            log_box,
            E('div', {'style':'text-align:right;font-size:12px; margin-top:5px;'}, hpTranslate('refresh_interval', 'Refresh every %s seconds.').format(L.env.pollinterval))
        ]);
    }
});
