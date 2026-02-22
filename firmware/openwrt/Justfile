PROFILE := "glinet_gl-mt6000"
PACKAGES := "map luci adguardhome wireguard-tools luci-proto-wireguard qrencode"
FILES := "../files"
# DISABLED_SERVICES := "dnsmasq"

IMAGE_BUILDER := "openwrt-imagebuilder-mediatek-filogic.Linux-x86_64"

default:
	@just --list

setup:
	wget https://downloads.openwrt.org/snapshots/targets/mediatek/filogic/{{IMAGE_BUILDER}}.tar.zst
	tar --zstd -xvf {{IMAGE_BUILDER}}.tar.zst
	rm {{IMAGE_BUILDER}}.tar.zst

build: setup
  make -C {{IMAGE_BUILDER}} image \
    PROFILE="{{PROFILE}}" \
    PACKAGES="{{PACKAGES}}" \
    FILES="{{FILES}}"

clean:
	rm -rf ./{{IMAGE_BUILDER}}*

info: setup
	make -C {{IMAGE_BUILDER}} info
