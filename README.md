# luci-app-hp-lite

`luci-app-hp-lite` is an OpenWrt LuCI integration package for `hp-lite`. It is used to configure and manage the `hp-lite` client and server through the LuCI web administration interface.

`hp-lite` is a lightweight intranet penetration tool. This project mainly provides LuCI pages, configuration files, init scripts, and package build support for OpenWrt, making it easier to use `hp-lite` on routers.

## Build into Firmware

Enter the OpenWrt source code or SDK directory:

```sh
cd /path/to/openwrt
```

Clone this project into the `package` directory:

```sh
git clone https://github.com/liuyi-htu/luci-app-hp-lite.git package/luci-app-hp-lite
```

Update and install feeds:

```sh
./scripts/feeds update -a
./scripts/feeds install -a
```

Enter the configuration menu:

```sh
make menuconfig
```

Select:

```text
LuCI -> Applications -> luci-app-hp-lite
```

If you want to build it into the firmware, compile the firmware directly after selecting it:

```sh
make V=s
```

If you only want to build the package separately:

```sh
make package/luci-app-hp-lite/compile V=s
```

After compilation, you can find the generated packages with:

```sh
find bin/packages \( -name '*hp-lite*.apk' -o -name '*hp-lite*.ipk' \)
```

## Package Installation

Please select the corresponding package format according to the package manager used by your OpenWrt firmware:

- Use `.apk` for firmware that uses `apk`
- Use `.ipk` for firmware that uses `opkg`

Do not mix the two formats.

### Install `.apk`

Upload the packages to the router:

```sh
scp luci-app-hp-lite-*.apk root@192.168.1.1:/tmp/
scp luci-i18n-hp-lite-zh-cn-*.apk root@192.168.1.1:/tmp/
```

Log in to the router and install them:

```sh
ssh root@192.168.1.1
apk add --allow-untrusted /tmp/luci-app-hp-lite-*.apk
apk add --allow-untrusted /tmp/luci-i18n-hp-lite-zh-cn-*.apk
```

### Install `.ipk`

Upload the packages to the router:

```sh
scp luci-app-hp-lite_*.ipk root@192.168.1.1:/tmp/
scp luci-i18n-hp-lite-zh-cn_*.ipk root@192.168.1.1:/tmp/
```

Log in to the router and install them:

```sh
ssh root@192.168.1.1
opkg update
opkg install /tmp/luci-app-hp-lite_*.ipk
opkg install /tmp/luci-i18n-hp-lite-zh-cn_*.ipk
```

If missing dependencies are reported, install `luci-base` and `uci` first, and make sure the dependency packages come from the same OpenWrt version and architecture.

## Usage

After installation, if the LuCI page does not appear immediately, refresh the cache:

```sh
rm -f /tmp/luci-indexcache*
rm -rf /tmp/luci-modulecache/
/etc/init.d/rpcd reload
```

Then open LuCI and go to:

```text
Services -> hp-lite
```

Configure the `hp-lite` client or server parameters on the page, and manage the service start, stop, and running status.
