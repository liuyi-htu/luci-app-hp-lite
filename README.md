# luci-app-hp-lite

LuCI support package for the `hp-lite` client on OpenWrt.

This repository contains the LuCI application source only. Built `.apk` and `.ipk` packages are published in GitHub Releases instead of being committed to the source tree.

## Build From Source

Use an OpenWrt source tree or SDK that matches your target device and firmware version.

1. Enter your OpenWrt buildroot or SDK:

   ```sh
   cd /path/to/openwrt
   ```

2. Clone this package into the package directory:

   ```sh
   git clone https://github.com/liuyi-htu/luci-app-hp-lite.git package/luci-app-hp-lite
   ```

3. Update and install feeds:

   ```sh
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```

4. Select the package:

   ```sh
   make menuconfig
   ```

   Enable:

   ```text
   LuCI -> Applications -> luci-app-hp-lite
   ```

5. Build the package:

   ```sh
   make package/luci-app-hp-lite/compile V=s
   ```

6. Find the generated packages:

   ```sh
   find bin/packages \( -name '*hp-lite*.apk' -o -name '*hp-lite*.ipk' \)
   ```

The output format depends on the OpenWrt SDK or buildroot you use:

- Newer apk-based SDKs generate `.apk` files.
- Older opkg-based SDKs generate `.ipk` files.

The output usually includes one matching pair:

- `luci-app-hp-lite-6.0-r2.apk`
- `luci-i18n-hp-lite-zh-cn-6.0-r2.apk`
- `luci-app-hp-lite_6.0-r2_all.ipk`
- `luci-i18n-hp-lite-zh-cn_6.0-r2_all.ipk`

## Automated Builds

The GitHub Actions workflow builds both package formats:

- `.ipk` with the OpenWrt 24.10.7 x86/64 SDK.
- `.apk` with the OpenWrt 25.12.4 x86/64 SDK.

Each workflow run uploads both package sets as artifacts. When a tag like `v6.0-r2` is pushed, the workflow also uploads the generated `.apk` and `.ipk` files to the GitHub Release for that tag.

## Offline Installation

Download the prebuilt files from the latest release:

https://github.com/liuyi-htu/luci-app-hp-lite/releases

Copy the packages that match your router firmware package manager:

```sh
scp luci-app-hp-lite-6.0-r2.apk root@192.168.1.1:/tmp/
scp luci-i18n-hp-lite-zh-cn-6.0-r2.apk root@192.168.1.1:/tmp/
```

or:

```sh
scp luci-app-hp-lite_6.0-r2_all.ipk root@192.168.1.1:/tmp/
scp luci-i18n-hp-lite-zh-cn_6.0-r2_all.ipk root@192.168.1.1:/tmp/
```

SSH into the router:

```sh
ssh root@192.168.1.1
```

Install `.apk` packages on apk-based firmware:

```sh
apk add --allow-untrusted /tmp/luci-app-hp-lite-6.0-r2.apk
apk add --allow-untrusted /tmp/luci-i18n-hp-lite-zh-cn-6.0-r2.apk
```

Install `.ipk` packages on opkg-based firmware:

```sh
opkg install /tmp/luci-app-hp-lite_6.0-r2_all.ipk
opkg install /tmp/luci-i18n-hp-lite-zh-cn_6.0-r2_all.ipk
```

Refresh LuCI caches and reload services if needed:

```sh
rm -f /tmp/luci-indexcache*
rm -rf /tmp/luci-modulecache/
/etc/init.d/rpcd reload
```

Then open LuCI and go to:

```text
Services -> hp-lite
```

## Notes

- Install packages built for the same OpenWrt version and package manager used by your firmware.
- Do not install `.apk` packages with `opkg`, and do not install `.ipk` packages with `apk`.
- This LuCI package depends on `luci-base` and `uci`.
- If dependency packages are missing on an offline router, install those dependency packages first.
- The `hp-lite` binary itself can be downloaded or uploaded from the LuCI page after installation.
