SYSTEM = windows
ifndef QTDIR
QTDIR = J:\Qt\2009.02\qt
endif
IMPLIB = implib /system /PAGESIZE:32
LIB_EXT = lib
DYN_LIB_EXT = dll
D_OBJ_EXT = obj
LIB_NAME_PREFIX =
LIB_LINK = mingw32 qtmain
BIN_EXT = .exe
GEN = release\generator$(BIN_EXT)
MKDIR = build\mkdir.bat
RM = build\rm.exe
SL = \\

CC_LFLAGS += -Wl -Wl,-subsystem,windows

ifndef QTDIR_INC
QTDIR_INC = $(QTDIR)\include
endif

ifndef QTDIR_LIB
QTDIR_LIB = $(QTDIR)\lib
endif

## Force CPP_SHARED on windows
ifeq ($(SYSTEM), windows)
CPP_SHARED = true
endif
QT_LIB_POSTFIX = 4