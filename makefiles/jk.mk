BUILD ?= build
packagename ?= pkg
BINARYDIR = $(BUILD)/$(packagename)/$(installdir)
name ?= a.out

$(shell mkdir -p $(BUILD))

JK_SDK = $(THEOS)/sdks/iPhoneOS13.4.sdk
lib = /usr/local/lib
include = /usr/local/include
vendor = $(THEOS)/vendor

CC = clang -isysroot $(JK_SDK)
#CXX = /usr/bin/clang++-10 -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

objects = $(foreach file, $(files), $(BUILD)/$(patsubst %.mm,%.o,$(patsubst %.xm,%.o,$(file:.m=.o))))
frameworkflags = $(foreach framework, $(frameworks), -framework $(framework))

ifdef library
mainlink = $(BUILD)/main.o
libflags = -L$(dir $(library)) -l$(patsubst lib%.a,%,$(notdir $(library)))
else
mainlink = $(objects)
libflags =
endif

all: $(BINARYDIR)/$(name)

white = \e[1;37m
logos_print= \e[0;31m==>$(white)
complile_print = @echo -e "\e[0;32m==>$(white) compiling $(patsubst %.xm,%.mm,$<) \e[0m"
link_print = @echo -e "\e[0;33m==>$(white) linking $(patsubst %.xm,%.mm,$<) \e[0m"

$(BINARYDIR)/$(name): $(mainlink) $(library)
	@mkdir -p $(BINARYDIR)
	$(link_print)
	@$(CXX) -L$(vendor)/lib -L$(lib) $(libflags) $(frameworkflags) $(ldflags) $(mainlink) -o $@
ifdef cpbinary
	cp $(BINARYDIR)/$(name) .
endif

$(BUILD)/%.o: %.xm $(headers)
	@$(shell if [ $< -nt $(BUILD)/$(patsubst %.xm,%.mm,$<) ]; then echo -e "\e[0;31m==>$(white) logos\e[0m" > `tty`; if ! $(THEOS)/bin/logos.pl $< > $(BUILD)/$(patsubst %.xm,%.mm,$<); then echo jkLOGOSFAILED; rm $(BUILD)/$(patsubst %.xm,%.mm,$<); fi; else echo no logos > `tty`;  fi)
	@cp $(BUILD)/$(patsubst %.xm,%.mm,$<) .
	$(complile_print)
	@$(CXX) $(flags) -c -I$(include) -I$(vendor)/include -I/usr/lib/llvm-10/include/c++/v1 $(patsubst %.xm,%.mm,$<) -o $@
	@rm $(patsubst %.xm,%.mm,$<)
	

$(BUILD)/%.o: %.m $(headers)
	@echo compiling $<
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $< -o $@

$(BUILD)/%.o: %.c $(headers)
	@echo compiling $<
	@$(CC) $(flags) -c -I$(include) -I$(vendor)/include $< -o $@

$(BUILD)/%.o: %.mm $(headers)
	@echo compiling $<
	@$(CXX) $(flags) -c -I$(include) -I$(vendor)/include -I/usr/lib/llvm-10/include/c++/v1 $< -o $@

$(library): $(objects)
	@$(AR) rvs $(library) $(objects)

$(include)/%.h: %.h
	@echo installing $<
	@cp $< $@

clean:
	@rm -f $(BUILD)/main.o $(objects) \
	$(library) $(name)

e: all
	./$(name)

a:clean all



JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LSUBSTRATE = -L$(vendor)/lib,-lsubstrate

dir_guard=@mkdir -p $(@D)
