## TODO: CPP_SHARED is very experemental on posix.
## TODO: "make clean" don`t work as expected.
## TODO: add target "install"
## TODO: delete 'lib' prefix from output library name under windows.

## Read variable from shell.
export QTDIR
export QTDIR_INC
export QTDIR_LIB
## End. Read variable from shell.

## Try identify system.
ifeq ($(strip $(shell uname)),Linux)
	SYSTEM=posix
else
	ifeq ($(strip $(shell uname)),Darwin)
		SYSTEM=posix
	else
		SYSTEM=windows
	endif
endif
## End, Try identify system.

## Load system specify settings.
include build/$(SYSTEM).makefile

## Main settings.
## D compiler.
ifndef $(DC)
DC = dmd
endif
## C++ compiler.
ifndef $(CC)
CC = g++
endif
## Archiver.
ifndef $(AR)
AR = ar
endif
## Set default target.
ifndef $(BUILD_TYPE)
BUILD_TYPE = release
endif

## Tmp path.
ifndef $(TMP_PATH)
TMP_PATH_ = tmp
TMP_PATH = $(TMP_PATH_)$(SL)$(BUILD_TYPE)
endif
## Output path.
ifndef $(OUTPUT_PATH)
OUTPUT_PATH = lib
endif
## Prefix for lib name.
ifndef $(NAME_PREFIX)
NAME_PREFIX = qtd
endif
ifndef $(PACKAGES)
PACKAGES = core
endif
LIB_PREFIX = lib
CC_INCLUDE += include $(QTDIR_INC) $(QTDIR_INC)$(SL)Qt $(QTDIR_INC)$(SL)QtCore $(QTDIR_INC)$(SL)QtGui $(QTDIR_INC)$(SL)QtOpenGL $(QTDIR_INC)$(SL)QtSvg
D_INCLUDE +=
CC_LFLAGS += -enable-stdcall-fixup -Wl,-enable-auto-import -Wl,-enable-runtime-pseudo-reloc -Wl,-s -mthreads
CC_CFLAGS +=
D_CFLAGS +=
CC_LIB_PATH += $(QTDIR_LIB) $(TMP_PATH)
D_LIB_PATH += $(TMP_PATH)

## D target
ifndef D_TARGET
D_TARGET = d1-tango
endif

ifeq ($(D_TARGET), d1-tango)
D_VERSION = 1
else
D_VERSION = 2
endif
D_CFLAGS += -Iqt/d$(D_VERSION)

#End. Main settings.

## Flags for debug version.
ifeq ($(BUILD_TYPE), debug)
CC_CFLAGS += -O0
D_CFLAGS += -debug -g -gc
LIB_POSTFIX = d
else ifeq ($(BUILD_TYPE), release)
## End. Flags for debug version.
## Flags for release version
CC_CFLAGS += -O
D_CFLAGS += -O -release -inline
endif
## End. Flags for release version.

## Load classes list.
## param 1 - package name.
define MODULE_template
    include build/$(1).makefile
    qt_$(1)_lib_name = $$(qt_$(1)_name)$(QT_LIB_POSTFIX)
    $(1)_cpp_files += $$($(1)_classes:%=cpp/qt_$(1)/%_shell.cpp)
    $(1)_cpp_obj_files = $$($(1)_cpp_files:cpp/%.cpp=$(TMP_PATH)/%.o)
    $(1)_d_files += $$($(1)_classes:%=qt/$(1)/%.d)
endef
$(foreach package,$(PACKAGES),$(eval $(call MODULE_template,$(package))))
## End. Load classes list

## DMD compile template bug fix
ifeq ($(DC), dmd)
NOT_SEPARATE_D_OBJ = true
endif

ifeq ($(SYSTEM), windows)
	ifeq ($(DC), dmd)
		DMD_WIN = true
	endif
endif

ifeq ($(DMD_WIN), true)
	CPP_SHARED = true
	LIB_EXT = lib
else
	LIB_EXT = a
endif

## CPP_SHARED options.
ifeq ($(CPP_SHARED), true)
CC_CFLAGS += -DCPP_SHARED
GEN_OPT   += --cpp_shared
D_CFLAGS += -version=cpp_shared
endif
## End. CPP_SHARED options.

all: dgen build

windows:
	$(MAKE) SYSTEM=windows

posix:
	$(MAKE) SYSTEM=posix

release: all

debug:
	$(MAKE) BUILD_TYPE=debug

build: mkdir $(PACKAGES)

## DGenerator
make_gen:
	cd generator && qmake && $(MAKE)

dgen:  make_gen
	cd generator && $(GEN) $(GEN_OPT) --d-target=$(D_TARGET) --output-directory=../ qtjambi_masterinclude.h build_core.txt
## DGenerator ## end

mkdir:
	@$(MKDIR) $(TMP_PATH_)
	@$(MKDIR) $(TMP_PATH)
	@$(MKDIR) $(TMP_PATH)$(SL)qt_qtd
	@$(MKDIR) $(TMP_PATH)$(SL)qtd
	@$(MKDIR) $(OUTPUT_PATH)

## Build cpp files.
$(TMP_PATH)/%.o: cpp/%.cpp
	$(CC) $(CC_CFLAGS) $(CC_INCLUDE:%=-I%) -c $(@:$(TMP_PATH)/%.o=cpp/%.cpp) -o$@

## Build d files.
$(TMP_PATH)/%_d.o: qt/%.d
	$(DC) $(D_CFLAGS) -c $(@:$(TMP_PATH)/%_d.o=qt/%.d) -of$@

## Build package.
## param 1 - package name.
define BUILD_template
    ## mkdir
    mkdir_$(1):
	    @$(MKDIR) $(TMP_PATH)$(SL)qt_$(1)
	    @$(MKDIR) $(TMP_PATH)$(SL)$(1)
    ## End. mkdir
    ## Build d part.
    ifeq ($(NOT_SEPARATE_D_OBJ), true)
    ## DMD compile template bug fix
    $(1)_D_RULE =$(TMP_PATH)/$(1)_dobj.$(D_OBJ_EXT)
    $$($(1)_D_RULE):
	    $(DC) $(D_CFLAGS) $(D_INCLUDE) -c $$($(1)_d_files) -of$$($(1)_D_RULE)
    else
    $(1)_D_RULE = $$($(1)_d_files:qt/%.d=$(TMP_PATH)/%_d.o)
    endif
    ## End. Build d part.
    ## Build cpp part.
    ifeq ($(CPP_SHARED), true)
    ifeq ($(SYSTEM), windows)
    $(1)_CPP_DYN_LIB = $(OUTPUT_PATH)$(SL)$(LIB_PREFIX)$(NAME_PREFIX)$(1)$(LIB_POSTFIX).$(DYN_LIB_EXT)
    $$($(1)_CPP_DYN_LIB): $$($(1)_cpp_obj_files)
	    $(CC) $(CC_LFLAGS) -shared $$($(1)_cpp_obj_files) -o $$($(1)_CPP_DYN_LIB) $(CC_LIB_PATH:%=-L%) -l$(qt_$(1)_lib_name) $$($(1)_link_cpp:%=-l%) -Wl,--out-implib,$(TMP_PATH)\$(LIB_PREFIX)$(NAME_PREFIX)$(1)_cpp.a
    $(1)_CPP_RULE = $(TMP_PATH)\cpp_$(1).$(LIB_EXT)
    $$($(1)_CPP_RULE): $$($(1)_CPP_DYN_LIB)
	    $(IMPLIB) $$($(1)_CPP_RULE) $$($(1)_CPP_DYN_LIB)
    else ## CPP_SHARED != true
    $(1)_CPP_RULE = $(OUTPUT_PATH)$(SL)$(LIB_PREFIX)$(NAME_PREFIX)$(1)$(LIB_POSTFIX).$(DYN_LIB_EXT)
    $$($(1)_CPP_RULE): $$($(1)_cpp_obj_files)
	    $(CC) $(CC_LFLAGS) $(QTDIR_LIB)/$(LIB_PREFIX)$(qt_$(1)_name).$(DYN_LIB_EXT) $$($(1)_link_cpp:%=-l%) $$($(1)_cpp_obj_files) -o $$($(1)_CPP_RULE)
    endif ## CPP_SHARED
    DELETE_FILES += $$($(1)_CPP_DYN_LIB) $$($(1)_cpp_obj_files) $(TMP_PATH)\$(LIB_PREFIX)$(NAME_PREFIX)$(1)_cpp.a
    else
    $(1)_CPP_RULE = $$($(1)_cpp_obj_files)
    endif
    ## End. Build cpp part.

    DELETE_FILES += $$($(1)_D_RULE) $$($(1)_CPP_RULE) $(OUTPUT_PATH)/$(LIB_PREFIX)$$(qt_$(1)_name)D.$(LIB_EXT)
    ## Implib link.
    $(1)_LIB = $(OUTPUT_PATH)$(SL)$(LIB_PREFIX)$(NAME_PREFIX)$(1)$(LIB_POSTFIX).$(LIB_EXT)
    ifeq ($(DMD_WIN), true)
    $$($(1)_LIB): $$($(1)_D_RULE) $$($(1)_CPP_RULE)
	    $(DC) $$($(1)_D_RULE) $$($(1)_CPP_RULE) $(D_LIB_PATH:%=-L-L%) $$($(1)_link_d:%=-L-l%) -lib -of$$($(1)_LIB)
    else
    $$($(1)_LIB): $$($(1)_D_RULE) $$($(1)_CPP_RULE)
	    $(AR) rcs $$($(1)_LIB) $$($(1)_D_RULE) $$($(1)_CPP_RULE)
    endif
    # End. Implib link.
    $(1): mkdir_$(1) $$($(1)_LIB)
endef
$(foreach package,$(PACKAGES),$(eval $(call BUILD_template,$(package))))
## End. Build package.

clean:
	@$(RM) $(DELETE_FILES)
