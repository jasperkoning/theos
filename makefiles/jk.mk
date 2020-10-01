JK_SDK = $(THEOS)/sdks/iPhoneOS13.5.sdk
JK_LIB = /usr/local/lib
JK_INCLUDE = /usr/local/include

CC = clang -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

JK_VENDOR = $(THEOS)/vendor
JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LSUBSTRATE = -L$(JK_VENDOR)/lib,-lsubstrate

dir_guard=@mkdir -p $(@D)