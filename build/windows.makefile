SYSTEM = windows
ifndef QTDIR
QTDIR = C:\eldar\Qt\qt
endif
IMPLIB = implib /system /PAGESIZE:32
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

QT_LIB_POSTFIX = 4