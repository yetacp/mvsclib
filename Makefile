# Makefile for MVS

USER=HERC01
PASS=CUL8TR
# --------------------------------------------
# System dependent
# --------------------------------------------
CC=gcc
GCCMVS = ../gccmvs/gccmvs
RDRPREP = ../playmvs/rdrprep/rdrprep
HERCHOST = 127.0.0.1
HERCPORT = 3505

all: linux/libmvsclib.a mvs_asm

# --------------------------------------------
# Linux
# --------------------------------------------
LINUX_C_OPTS=-c -O2 -fno-builtin -fno-stack-protector -m32 -DUSE_MEMMGR -I common/include 
LINUX_C_SOURCE:=$(wildcard ./common/src/*.c )
LINUX_OBJ:=$(subst .c,.o,$(LINUX_C_SOURCE) )

.c.o:
	$(CC) $(LINUX_C_OPTS) $< -o $@

linux/asm/linsupa.o: linux/asm/linsupa.asm
	as --32 -o $@ $<

linux/libmvsclib.a: $(LINUX_OBJ) linux/asm/linsupa.o
	ar r linux/libmvsclib.a $(LINUX_OBJ) linux/asm/linsupa.o

# --------------------------------------------
# MVS
# --------------------------------------------
MVS_INCLUDES = -I common/include -I mvs/include
MVS_OPTS   = -S -Os -DXXX_MEMMGR $(MVS_INCLUDES)
MVS_C_SOURCE:=$(wildcard ./common/src/*.c)
MVS_C_SOURCE+=$(wildcard ./mvs/src/ezasmi/*.c)
MVS_C_SOURCE+=$(wildcard ./mvs/src/fss/*.c)

MVS_S:=$(subst .c,.s,$(MVS_C_SOURCE))

mvs_asm: $(MVS_S)
	m4 -D__USER__=$(USER) -D__PASS__=$(PASS) \
	   -I mvs/maclib/ -I mvs/asm/ -I common/src/ \
	   job_mvs_template.m4 > job_mvs.jcl

.c.s:
	$(GCCMVS) $(MVS_OPTS) $< -o $@

send_ascii:
	nc -w1 $(HERCHOST) $(HERCPORT) < job_mvs.jcl

send_ebcdic:
	$(RDRPREP) job_mvs.jcl tmp.jcl_E
	nc -w1 $(HERCHOST) $(HERCPORT) < tmp.jcl_E

clean:
	@rm -f common/src/*.o common/src/*.s \
		   linux/asm/linsupa.o linux/libmvsclib.a \
		   mvs/src/ezasmi/*.s mvs/src/fss/*.s \
		   job_mvs.jcl
