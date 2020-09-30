JK_VENDOR = $(THEOS)/vendor
JK_SDK = $(THEOS)/sdks/iPhoneOS13.5.sdk
JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LIB = /opt/lib
JK_INCLUDE = /opt/include
