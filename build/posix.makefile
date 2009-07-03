SYSTEM = posix
ifndef QTDIR
QTDIR = /usr/share/qt4
ifndef QTDIR_INC
QTDIR_INC = /usr/include/qt4
endif
ifndef QTDIR_LIB
QTDIR_LIB = /usr/lib
endif
else
ifndef QTDIR_INC
QTDIR_INC = $(QTDIR)/include
endif
ifndef QTDIR_LIB
QTDIR_LIB = $(QTDIR)/lib
endif
endif
DYN_LIB_EXT = so
D_OBJ_EXT = o
LIB_NAME_PREFIX = lib
GEN = ./generator
MKDIR = mkdir -p
RM = rm -f
SL = /

