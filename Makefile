include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-hp-lite
PKG_VERSION:=2.0
PKG_RELEASE:=1
PKG_PO_VERSION:=$(PKG_VERSION)-r$(PKG_RELEASE)
PKG_MAINTAINER:=zyh <1540187368@qq.com>
PKG_LICENSE:=Apache-2.0
PKG_LICENSE_FILES:=LICENSE

LUCI_TITLE:=LuCI Support for hp lite
LUCI_DEPENDS:=+luci-base +uci
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/postinst
#!/bin/sh
chmod 755 "$${IPKG_INSTROOT}/etc/init.d/hp-litec" 2>/dev/null || true
chmod 755 "$${IPKG_INSTROOT}/etc/init.d/hp-lites" 2>/dev/null || true
rm -f "$${IPKG_INSTROOT}/etc/init.d/hp-lite" 2>/dev/null || true
rm -f "$${IPKG_INSTROOT}"/etc/rc.d/*hp-lite 2>/dev/null || true
[ -n "$${IPKG_INSTROOT}" ] || {
	if ! uci -q get hp-litec.global >/dev/null 2>&1; then
		uci set hp-litec.global='hp-litec'
	fi
	[ -n "$$(uci -q get hp-litec.global.connect_code 2>/dev/null)" ] || uci set hp-litec.global.connect_code=''
	if [ -z "$$(uci -q get hp-litec.global.log_file 2>/dev/null)" ]; then
		_client_log_dir="$$(uci -q get hp-litec.global.log_dir 2>/dev/null)"
		[ -n "$$_client_log_dir" ] || _client_log_dir='/var/log/hp-lite'
		_client_log_dir="$${_client_log_dir%/}"
		uci set hp-litec.global.log_file="$$_client_log_dir/hp-litec.log"
	fi
	[ -n "$$(uci -q get hp-litec.global.log_retention_days 2>/dev/null)" ] || uci set hp-litec.global.log_retention_days='3'
	uci commit hp-litec

	if ! uci -q get hp-lites.server >/dev/null 2>&1; then
		uci set hp-lites.server='hp-lites'
	fi
	if [ -z "$$(uci -q get hp-lites.server.log_file 2>/dev/null)" ]; then
		_server_log_dir="$$(uci -q get hp-lites.server.log_dir 2>/dev/null)"
		[ -n "$$_server_log_dir" ] || _server_log_dir='/var/log/hp-lite'
		_server_log_dir="$${_server_log_dir%/}"
		uci set hp-lites.server.log_file="$$_server_log_dir/hp-lites.log"
	fi
	[ -n "$$(uci -q get hp-lites.server.log_retention_days 2>/dev/null)" ] || uci set hp-lites.server.log_retention_days='3'
	uci commit hp-lites

	if [ -f /etc/crontabs/root ]; then
		sed -i '/# hp-litec-log-clean/d; /# hp-lites-log-clean/d; /# hp-lite-log-clean/d' /etc/crontabs/root 2>/dev/null || true
		/etc/init.d/cron reload >/dev/null 2>&1 || /etc/init.d/cron restart >/dev/null 2>&1 || true
	fi

	rm -f /tmp/luci-indexcache*
	rm -rf /tmp/luci-modulecache/
	/etc/init.d/rpcd reload 2>/dev/null || true
}
exit 0
endef

define Package/$(PKG_NAME)/prerm
#!/bin/sh
case "$$1" in
	remove|purge|deinstall|uninstall|"")
		if [ -z "$${IPKG_INSTROOT}" ]; then
			[ -x /etc/init.d/hp-lites ] && /etc/init.d/hp-lites stop >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-litec ] && /etc/init.d/hp-litec stop >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-lites ] && /etc/init.d/hp-lites disable >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-litec ] && /etc/init.d/hp-litec disable >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-lite ] && /etc/init.d/hp-lite stop_server >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-lite ] && /etc/init.d/hp-lite stop >/dev/null 2>&1 || true
			[ -x /etc/init.d/hp-lite ] && /etc/init.d/hp-lite disable >/dev/null 2>&1 || true
		fi

		ROOT="$${IPKG_INSTROOT}"
		CRON="$${ROOT}/etc/crontabs/root"

		if [ -f "$${CRON}" ]; then
			sed -i '/# hp-litec-log-clean/d; /# hp-lites-log-clean/d; /# hp-lite-log-clean/d' "$${CRON}" 2>/dev/null || true
		fi

		rm -f "$${ROOT}/usr/bin/hp-litec"
		rm -f "$${ROOT}/usr/bin/hp-lites"
		rm -f "$${ROOT}/usr/bin/hp-lite"
		rm -f "$${ROOT}/tmp/hp-litec.upload"
		rm -f "$${ROOT}/tmp/hp-lites.upload"
		rm -f "$${ROOT}/tmp/hp-lite.upload"
		rm -f "$${ROOT}/etc/config/hp-litec"
		rm -f "$${ROOT}/etc/config/hp-lites"
		rm -f "$${ROOT}/etc/init.d/hp-lite"
		rm -f "$${ROOT}/etc/init.d/hp-litec"
		rm -f "$${ROOT}/etc/init.d/hp-lites"
		rm -f "$${ROOT}"/etc/rc.d/*hp-lite 2>/dev/null || true
		rm -f "$${ROOT}"/etc/rc.d/*hp-litec 2>/dev/null || true
		rm -f "$${ROOT}"/etc/rc.d/*hp-lites 2>/dev/null || true
		rm -rf "$${ROOT}/var/log/hp-lite"
		rm -rf "$${ROOT}/tmp/hp-lite"
		rm -rf "$${ROOT}/tmp/hp-litec"
		rm -rf "$${ROOT}/etc/hp-lite"
		rm -f "$${ROOT}"/tmp/luci-indexcache*
		rm -rf "$${ROOT}/tmp/luci-modulecache"

		if [ -z "$${ROOT}" ] && [ -x /etc/init.d/cron ]; then
			/etc/init.d/cron reload >/dev/null 2>&1 || /etc/init.d/cron restart >/dev/null 2>&1 || true
		fi
		;;
esac
exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
case "$$1" in
	remove|purge|deinstall|uninstall|"")
		;;
	*)
		exit 0
		;;
esac

ROOT="$${IPKG_INSTROOT}"
CRON="$${ROOT}/etc/crontabs/root"

if [ -f "$${CRON}" ]; then
	sed -i '/# hp-litec-log-clean/d; /# hp-lites-log-clean/d; /# hp-lite-log-clean/d' "$${CRON}" 2>/dev/null || true
fi

rm -f "$${ROOT}/usr/bin/hp-litec"
rm -f "$${ROOT}/usr/bin/hp-lites"
rm -f "$${ROOT}/usr/bin/hp-lite"
rm -f "$${ROOT}/tmp/hp-litec.upload"
rm -f "$${ROOT}/tmp/hp-lites.upload"
rm -f "$${ROOT}/tmp/hp-lite.upload"
rm -f "$${ROOT}/etc/config/hp-litec"
rm -f "$${ROOT}/etc/config/hp-lites"
rm -f "$${ROOT}/etc/init.d/hp-lite"
rm -f "$${ROOT}/etc/init.d/hp-litec"
rm -f "$${ROOT}/etc/init.d/hp-lites"
rm -f "$${ROOT}"/etc/rc.d/*hp-lite 2>/dev/null || true
rm -f "$${ROOT}"/etc/rc.d/*hp-litec 2>/dev/null || true
rm -f "$${ROOT}"/etc/rc.d/*hp-lites 2>/dev/null || true
rm -rf "$${ROOT}/var/log/hp-lite"
rm -rf "$${ROOT}/tmp/hp-lite"
rm -rf "$${ROOT}/tmp/hp-litec"
rm -rf "$${ROOT}/etc/hp-lite"
rm -f "$${ROOT}"/tmp/luci-indexcache*
rm -rf "$${ROOT}/tmp/luci-modulecache"

if [ -z "$${ROOT}" ] && [ -x /etc/init.d/cron ]; then
	/etc/init.d/cron reload >/dev/null 2>&1 || /etc/init.d/cron restart >/dev/null 2>&1 || true
fi

exit 0
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
