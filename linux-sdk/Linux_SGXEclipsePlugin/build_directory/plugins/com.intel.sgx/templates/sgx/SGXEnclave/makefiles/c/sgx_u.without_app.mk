######## SGX SDK Settings ########
SGX_SDK ?= $(SdkPathFromPlugin)
SGX_MODE ?= SIM
SGX_ARCH ?= x64
UNTRUSTED_DIR=untrusted

ifeq ($(shell getconf LONG_BIT), 32)
	SGX_ARCH := x86
else ifeq ($(findstring -m32, $(CXXFLAGS)), -m32)
	SGX_ARCH := x86
endif

ifeq ($(SGX_ARCH), x86)
	SGX_COMMON_CFLAGS := -m32
	SGX_EDGER8R := $(SGX_SDK)/bin/x86/sgx_edger8r
else
	SGX_COMMON_CFLAGS := -m64
	SGX_EDGER8R := $(SGX_SDK)/bin/x64/sgx_edger8r
endif

ifeq ($(SGX_DEBUG), 1)
ifeq ($(SGX_PRERELEASE), 1)
$(error Cannot set SGX_DEBUG and SGX_PRERELEASE at the same time!!)
endif
endif

ifeq ($(SGX_DEBUG), 1)
        SGX_COMMON_CFLAGS += -O0 -g
else
        SGX_COMMON_CFLAGS += -O2
endif

######## App Settings ########

App_Include_Paths := -IInclude -I$(UNTRUSTED_DIR) -I$(SGX_SDK)/include

App_C_Flags := $(SGX_COMMON_CFLAGS) -fPIC -Wno-attributes $(App_Include_Paths)

# Three configuration modes - Debug, prerelease, release
#   Debug - Macro DEBUG enabled.
#   Prerelease - Macro NDEBUG and EDEBUG enabled.
#   Release - Macro NDEBUG enabled.
ifeq ($(SGX_DEBUG), 1)
        App_C_Flags += -DDEBUG -UNDEBUG -UEDEBUG
else ifeq ($(SGX_PRERELEASE), 1)
        App_C_Flags += -DNDEBUG -DEDEBUG -UDEBUG
else
        App_C_Flags += -DNDEBUG -UEDEBUG -UDEBUG
endif


.PHONY: all run

all: $(UNTRUSTED_DIR)/$(enclaveName)_u.o

######## App Objects ########

$(UNTRUSTED_DIR)/$(enclaveName)_u.c: $(SGX_EDGER8R) trusted/$(enclaveName).edl
	@mkdir -p $(UNTRUSTED_DIR)
	@cd $(UNTRUSTED_DIR) && $(SGX_EDGER8R) --untrusted ../trusted/$(enclaveName).edl --search-path ../trusted --search-path $(SGX_SDK)/include
	@echo "GEN  =>  $@"

$(UNTRUSTED_DIR)/$(enclaveName)_u.o: $(UNTRUSTED_DIR)/$(enclaveName)_u.c
	@$(CC) $(App_C_Flags) -c $< -o $@
	@echo "CC   <=  $<"

.PHONY: clean

clean:
	@rm -f  $(UNTRUSTED_DIR)/$(enclaveName)_u.* 
