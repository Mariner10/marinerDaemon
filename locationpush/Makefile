THEOS_DEVICE_IP = 192.168.1.19
TARGET := iphone:clang:latest:7.0
DEBUG = 1
FINALPACKAGE = 0

include $(THEOS)/makefiles/common.mk

TOOL_NAME = LocationPushDaemon


LocationPushDaemon_FILES = Tweak.xm
LocationPushDaemon_CFLAGS = -fobjc-arc
LocationPushDaemon_FRAMEWORKS = CoreLocation
LocationPushDaemon_PRIVATE_FRAMEWORKS = CoreTelephony
LocationPushDaemon_CODESIGN_FLAGS = -Sentitlements.plist
LocationPushDaemon_INSTALL_PATH = /usr/local/bin

ARCHS = arm64 arm64e

include $(THEOS_MAKE_PATH)/tool.mk

after-install::
	install.exec "launchctl unload /Library/LaunchDaemons/com.mariner.locationpush.plist || true"
	install.exec "launchctl load /Library/LaunchDaemons/com.mariner.locationpush.plist"
	install.exec "killall -9 SpringBoard"