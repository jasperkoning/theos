JK_VENDOR = $(THEOS)/vendor
JK_SDK = $(THEOS)/sdks/iPhoneOS13.5.sdk
JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LIB = /usr/local/lib
JK_INCLUDE = /usr/local/include
JK_LSUBSTRATE = -L$(JK_VENDOR)/lib,-lsubstrate
