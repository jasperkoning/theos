BUILD ?= build
name ?= a.out

$(shell mkdir -p $(BUILD))

JK_SDK = $(THEOS)/sdks/iPhoneOS13.4.sdk
lib = /usr/local/lib
include = /usr/local/include
vendor = $(THEOS)/vendor

CC = clang -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

objects = $(foreach file, $(files), $(BUILD)/$(patsubst %.mm,%.o,$(file:.m=.o)))
frameworkflags = $(foreach framework, $(frameworks), -framework $(framework))

ifdef library
mainlink = $(BUILD)/main.o
libflags = -L$(dir $(library)) -l$(patsubst lib%.a,%,$(notdir $(library)))
else
mainlink = $(objects)
libflags =
endif

all: $(name)

$(name): $(mainlink) $(library)
	@echo linking: $(notdir $^)
	@$(CXX) -L$(vendor)/lib -L$(lib) $(libflags) $(frameworkflags) $(ldflags) $(mainlink) -lc++abi -o $(name)

$(BUILD)/%.o: %.m $(headers)
	@echo compiling $<
	@$(CC) $(flags) -c -I$(include) $< -o $@

$(BUILD)/%.o: %.c $(headers)
	@echo compiling $<
	@$(CC) $(flags) -c -I$(include) $< -o $@

$(BUILD)/%.o: %.mm $(headers)
	@echo compiling $<
	$(CXX) $(flags) -c -I$(include) -I/usr/lib/llvm-10/include/c++/v1 $< -o $@

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
