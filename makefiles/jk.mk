BUILD ?= build
name ?= a.out
packagename ?= $(basename $(name))
plistfile ?= $(basename $(name)).plist
controlfile ?= control

ifeq ($(type),tweak)
kill_target ?= killall -9 backboardd
installdir ?= /Library/MobileSubstrate/DynamicLibraries
ldflags += -shared -lsubstrate
copy_resources = cp $(plistfile) $(BUILD)/$(packagename)/$(installdir)/$(plistfile)
else ifeq ($(type),app)
kill_target = killall -9 $(name) 2>/dev/null || true
installdir ?= /Applications/$(name).app
copy_resources = cp Resources/* $(BUILD)/$(packagename)/$(installdir)/
else ifeq ($(type),tool)
installdir ?= /usr/local/bin
else
$(shell echo specify type > `tty`)
error
endif
BINARYDIR = $(BUILD)/$(packagename)/$(installdir)

ifndef fobjc-arc
flags += -fobjc-arc
endif

$(shell mkdir -p $(BUILD))

JK_SDK = $(THEOS)/sdks/iPhoneOS13.4.sdk
lib = /usr/local/lib
include = /usr/local/include
vendor = $(THEOS)/vendor

objects = $(foreach file, $(files), $(BUILD)/$(patsubst %.c,%.o,$(patsubst %.mm,%.o,$(patsubst %.xm,%.o,$(patsubst %.x,%.o,$(patsubst %.swift,%.o,$(file:.m=.o)))))))
frameworkflags = $(foreach framework, $(frameworks), -framework $(framework))

ifdef library
mainlink = $(BUILD)/main.o
libflags = -L$(dir $(library)) -l$(patsubst lib%.a,%,$(notdir $(library)))
else
mainlink = $(objects)
libflags =
endif


all: start $(BINARYDIR)/$(name)
ifdef sub
	@$(MAKE) --no-print-directory -f $(sub)
endif

start:
#	@$(shell echo -e "\e[1;30m$(name)$(nocolor)" > `tty`)
	@echo -e "\e[1;30m$(name)$(nocolor)"

white = \e[1;37m
nocolor = \e[0m
logos_print= \e[0;36m>>>$(white)
compile_print = @echo -e "\e[0;32m>>>$(white) compiling $(patsubst %.xm,%.mm,$<) $(nocolor)"
link_print = @echo -e "\e[0;33m>>>$(white) linking $(patsubst Makefile,,$(notdir $^)) $(nocolor)"
sign_print = @echo -e "\e[0;35m>>>$(white) signing$(nocolor)"

CC = clang -isysroot $(JK_SDK)
# CXX = /usr/bin/clang++-10 -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

$(BINARYDIR)/$(name): $(mainlink) $(library) Makefile
	@mkdir -p $(BINARYDIR)
	$(link_print)
ifneq ($(findstring .swift,$(files)),)
	swiftc -sdk $(JK_SDK) $(frameworkflags) $(mainlink) -o $@
else
	@$(CXX) -F$(JK_SDK)/System/Library/PrivateFrameworks -L$(vendor)/lib -L$(lib) $(libflags) $(frameworkflags) $(ldflags) $(mainlink) -o $@
endif
ifdef entitlements
	$(sign_print)
	@ldid -S$(entitlements) $@
endif
ifdef cpbinary
	cp $(BINARYDIR)/$(name) .
endif

$(BUILD)/%.o: %.swift
	swiftc -I$(include) -I$(vendor) $(flags) -c -sdk $(JK_SDK) $(frameworkflags) $(files) -o $@

$(BUILD)/%.o: %.x $(headers)
	@$(shell if [ $< -nt $(BUILD)/$(patsubst %.x,%.m,$<) ]; then echo -e "\e[0;36m>>>$(white) logos$(nocolor)" > `tty`; if ! $(THEOS)/bin/logos.pl $< > $(BUILD)/$(patsubst %.x,%.m,$<); then echo jkLOGOSFAILED; rm $(BUILD)/$(patsubst %.x,%.m,$<); fi; else echo no logos > `tty`;  fi)
	@cp $(BUILD)/$(patsubst %.x,%.m,$<) .
	$(compile_print)
ifneq ($(findstring .xx,$<),)
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $(patsubst %.x,%.m,$<) -o $@
else
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $(patsubst %.x,%.m,$<) -o $@
endif
	@rm $(patsubst %.x,%.m,$<)

$(BUILD)/%.o: %.xm $(headers)
	@$(shell if [ $< -nt $(BUILD)/$(patsubst %.xm,%.mm,$<) ]; then echo -e "\e[0;36m>>>$(white) logos$(nocolor)" > `tty`; if ! $(THEOS)/bin/logos.pl $< > $(BUILD)/$(patsubst %.xm,%.mm,$<); then echo jkLOGOSFAILED; rm $(BUILD)/$(patsubst %.xm,%.mm,$<); fi; else echo no logos > `tty`;  fi)
	@cp $(BUILD)/$(patsubst %.xm,%.mm,$<) .
	$(compile_print)
ifneq ($(findstring .xx,$<),)
	@$(CXX) $(flags) -c -I$(include) -I$(vendor)/include -I/usr/lib/llvm-10/include/c++/v1 $(patsubst %.xm,%.mm,$<) -o $@
else
	@$(CXX) $(flags) -c -I$(include) -I$(vendor)/include -I/usr/lib/llvm-10/include/c++/v1 $(patsubst %.xm,%.mm,$<) -o $@
endif
	@rm $(patsubst %.xm,%.mm,$<)


$(BUILD)/%.o: %.m $(headers)
	$(compile_print)
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $< -o $@

$(BUILD)/%.o: %.c $(headers)
	$(compile_print)
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $< -o $@

$(BUILD)/%.o: %.mm $(headers)
	$(compile_print)
	@$(CXX) $(flags) -c -I$(include) -I$(vendor)/include -I/usr/lib/llvm-10/include/c++/v1 $< -o $@

$(library): $(objects)
	@$(AR) rvs $(library) $(objects)

$(include)/%.h: %.h
	@echo installing $<
	@cp $< $@

package: all $(BINARYDIR)/$(name) $(plistfile)
	@$(copy_resources)
	@mkdir -p $(BUILD)/$(packagename)/DEBIAN
	@cp control $(BUILD)/$(packagename)/DEBIAN/control
	@dpkg-deb --build $(BUILD)/$(packagename)

install:
	@dpkg -i $(BUILD)/$(packagename).deb
	@echo -e "\e[1;30m$(kill_target)$(nocolor)"
	@$(kill_target) 2> /dev/null || true

c: clean

clean:
	rm -r $(BUILD)/*

remove:
	@$(shell echo -e "\e[1;30mdpkg -r "`grep $(controlfile) -e Package:|sed 's/Package://g'|xargs`"$(nocolor)" > `tty`)
	@$(shell if [[ ! `dpkg -r \`grep $(controlfile) -e Package:|sed 's/Package://g'\`` ]]; then echo breek_af; fi)
	@$(kill_target)

e: all
	./$(BINARYDIR)/$(name)

a:clean all

pi:package install



JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LSUBSTRATE = -L$(vendor)/lib,-lsubstrate

dir_guard=@mkdir -p $(@D)





# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
