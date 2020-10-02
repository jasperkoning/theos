BUILD = build
name ?= a

$(shell mkdir -p $(BUILD))

JK_SDK = $(THEOS)/sdks/iPhoneOS13.5.sdk
lib = /usr/local/lib
include = /usr/local/include
vendor = $(THEOS)/vendor

CC = clang -isysroot $(JK_SDK)
CXX = clang++ -isysroot $(JK_SDK)

objects = $(foreach file, $(files), \
  $(BUILD)/$(patsubst %.mm,%.o,$(file:.m=.o)))

ifdef library
mainlink = $(BUILD)/main.o
else
mainlink = $(objects)
endif

all: $(name) $(headers)
	./$(name)

$(name): $(mainlink) $(library)
	@echo linking: $(notdir $^)
	@$(CC) $(flags) $(mainlink) -o $(name)

$(BUILD)/%.o: %.m
	@echo compiling $<
	@$(CC) -c -I$(include) $< -o $@

$(BUILD)/%.o: %.mm
	@echo compiling $<
	@$(CXX) -c -I$(include) $< -o $@

$(library): $(objects)
	@$(AR) rvs $(library) $(objects)

$(include)/%.h: %.h
	@echo installing $<
	@cp $< $@
	
clean:
	@rm -f $(BUILD)/main.o $(objects) \
	$(library) $(headers) $(name)
	
	


JK_SYSROOT = -isysroot $(JK_SDK)
JK_CLANG = clang $(JK_SYSROOT)
JK_CLANG++ = clang++ $(JK_SYSROOT)
JK_LSUBSTRATE = -L$(vendor)/lib,-lsubstrate

dir_guard=@mkdir -p $(@D)
