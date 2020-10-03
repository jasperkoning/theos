BUILD ?= build
name ?= a.out

$(shell mkdir -p $(BUILD))

JK_SDK = $(THEOS)/sdks/iPhoneOS13.5.sdk
lib = /usr/local/lib
include = /usr/local/include
vendor = $(THEOS)/vendor

CC = clang -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

objects = $(foreach file, $(files), $(BUILD)/$(patsubst %.mm,%.o,$(file:.m=.o)))
frameworkflags = $(foreach framework, $(frameworks), -framework $(framework))

ifdef library
mainlink = $(BUILD)/main.o
else
mainlink = $(objects)
endif

all: $(name) $(headers)
	./$(name)

$(name): $(mainlink) $(library)
	@echo linking: $(notdir $^)
	@$(CC) $(frameworkflags) $(ldflags) $(mainlink) -o $(name)

$(BUILD)/%.o: %.m
	@echo compiling $<
	@$(CC) $(flags) -c -I$(include) $< -o $@

$(BUILD)/%.o: %.mm
	@echo compiling $<
	@$(CXX) $(flags) -c -I$(include) $< -o $@

$(library): $(objects)
	@$(AR) rvs $(library) $(objects)

$(include)/%.h: %.h
	@echo installing $<
	@cp $< $@

clean:
	@rm -f $(BUILD)/main.o $(objects) \
	$(library) $(headers) $(name)

a:clean all



JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LSUBSTRATE = -L$(vendor)/lib,-lsubstrate

dir_guard=@mkdir -p $(@D)
