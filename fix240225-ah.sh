#!/bin/sh

MYEXT="-ah"
MYNAME=fix240225${MYEXT}.sh

# common code, functions
### return code/error code
RET_TRUE=1		# TRUE
RET_FALSE=0		# FALSE
RET_OK=0		# OK
RET_NG=1		# NG
RET_YES=1		# YES
RET_NO=0		# NO
RET_CANCEL=2		# CANCEL

ERR_USAGE=1		# usage
ERR_UNKNOWN=2		# unknown error
ERR_NOARG=3		# no argument
ERR_BADARG=4		# bad argument
ERR_NOTEXISTED=10	# not existed
ERR_EXISTED=11		# already existed
ERR_NOTFILE=12		# not file
ERR_NOTDIR=13		# not dir
ERR_CANTCREATE=14	# can't create
ERR_CANTOPEN=15		# can't open
ERR_CANTCOPY=16		# can't copy
ERR_CANTDEL=17		# can't delete
ERR_BADSETTINGS=18	# bad settings
ERR_BADENVIRONMENT=19	# bad environment
ERR_BADENV=19		# bad environment, short name

### flags
VERBOSE=0		# -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE	# -n --noexec flag
FORCE=$RET_FALSE	# -f --force flag
NODIE=$RET_FALSE	# -nd --nodie
NOCOPY=$RET_FALSE	# -ncp --nocopy
NOTHING=

###
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
ESC=$(printf '\033')
ESCBLACK="${ESC}[30m"
ESCRED="${ESC}[31m"
ESCGREEN="${ESC}[32m"
ESCYELLOW="${ESC}[33m"
ESCBLUE="${ESC}[34m"
ESCMAGENTA="${ESC}[35m"
ESCCYAN="${ESC}[36m"
ESCWHITEL="${ESC}[37m"
ESCDEFAULT="${ESC}[38m"
ESCBACK="${ESC}[m"
ESCRESET="${ESC}[0m"

ESCOK="$ESCGREEN"
ESCERR="$ESCRED"
ESCWARN="$ESCMAGENTA"
ESCINFO="$ESCWHITE"


# func:xxmsg ver:2023.12.23
# more verbose message to stderr
# xxmsg "messages"
xxmsg()
{
	if [ $VERBOSE -ge 2 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

# func:xmsg ver:2023.12.23
# verbose message to stderr
# xmsg "messages"
xmsg()
{
	if [ $VERBOSE -ge 1 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

# func:emsg ver:2023.12.31
# error message to stderr
# emsg "messages"
emsg()
{
        echo "$MYNAME: ${ESCERR}$*${ESCBACK}" 1>&2
}

# func:okmsg ver:2024.01.01
# ok message to stdout
# okmsg "messages"
okmsg()
{
        echo "$MYNAME: ${ESCOK}$*${ESCBACK}"
}

# func:msg ver:2023.12.23
# message to stdout
# msg "messages"
msg()
{
	echo "$MYNAME: $*"
}

###
TOPDIR=ggml
NAMEBASE=fix

CMD=chk
RESULT=0
DT0=
DT1=

###
#do_cp ggml.c	ggml.c.1001	ggml.c.1001mod

# diff old $1 $2 $OPT
diff_old()
{
	# in $TOPDIR

	xmsg "diff_old: CMD:$CMD $1 $2 $3 $4  OPT:$OPT"

	local NEWDATE NEW OLD

	if [ ! x"$OPT" = x ]; then
		NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][01][0-9][0-3][0-9]\)/\2/'`
		#msg "diff: NEW:$NEWDATE"
		if [ ! x"$NEWDATE" = x"$OPT" ]; then
			msg "diff: skip $2 by $NEWDATE"
			return
		fi
	fi

	#msg "diff_old $1 $2"
	NEW="./$2"
	OLD=`find . -path './'$1'.[0-9][0-9][01][0-9][0-3][0-9]' | awk -v NEW="$NEW" '
	$0 != NEW { OLD=$0 }
	END   { print OLD }'`
	okmsg "diff -c $OLD $NEW"
	diff -c $OLD $NEW
}

# do_cp target origin modified
do_cp()
{
	xmsg "do_cp: CMD:$CMD $1 $2 $3 $4"

	local FILES

	FILES="$1 $2"
	if [ -f $3 ]; then
		FILES="$FILES $3"
	fi
	if [ $# = 4 ]; then
		if [ -f $4 ]; then
			FILES="$FILES $4"
		fi
	fi

	# check
	case $CMD in
	chk|check)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $1 ]; then
			okmsg "diff -c $2 $1"
			diff -c $2 $1
			xmsg "RESULT: $RESULT $?"
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod|checkmod|chkgq|checkgq)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $3 ]; then
			okmsg "diff -c $1 $3"
			diff -c $1 $3
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod2|checkmod2|gqmod|checkgqmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				okmsg "diff -c $1 $4"
				diff -c $1 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				okmsg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				okmsg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	chkmod12|checkmod12|chkgqgqmod|checkgqgqmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				okmsg "diff -c $3 $4"
				diff -c $3 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				okmsg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				okmsg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	master)
		msg "cp -p $2 $1"
		cp -p $2 $1
		RESULT=`expr $RESULT + $?`
		;;
	mod|gq)
		if [ -f $3 ]; then
			msg "cp -p $3 $1"
			cp -p $3 $1
			RESULT=`expr $RESULT + $?`
		fi
		;;
	mod2)
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "cp -p $4 $1"
				cp -p $4 $1
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "cp -p $3 $1"
				cp -p $3 $1
				RESULT=`expr $RESULT + $?`
			fi
		fi
		;;
	diff)
		msg "diff: $1 $2"
		diff_old $1 $2
		;;
	*)	emsg "unknown command: $CMD"
		;;
	esac
}

do_mk()
{
	msg "making new $NAMEBASE script $NAMEBASE$DT1.sh and copy backup files ..."

#do_cp ggml.c		  ggml.c.0420		  ggml.c.0420mod    ggml.c.0420mod2
#do_cp examples/CMakeLists.txt examples/CMakeLists.txt.0413 examples/CMakeLists.txt.0415mod
#do_cp examples/benchmark/benchmark-q4_0-matmult.cpp	examples/benchmark/benchmark-q4_0-matmult.c.0417	examples/benchmark/benchmark-q4_0-matmult.cpp.0417mod	examples/benchmark/benchmark-q4_0-matmult.cpp.0423mod
	cat $MYNAME | awk -v DT0=$DT0 -v DT1=$DT1 -v TOP="$TOPDIR" '
	function exists(file) {
		n=(getline _ < file);
		#printf "# n:%d %s\n",n,file;
		if (n > 0) {
			return 1; # found
		} else if (n == 0) {
			return 1; # empty
		}
		return 0; # error
	}
	function update(L) {
		NARG=split(L, ARG, /[ \t]/);
		TOPFILE=TOP "/" ARG[2]
		TOPFILEDT1=TOP "/" ARG[2] "." DT1
		#if (exists(TOPFILE)==0) { printf "# %s\n",L; return 1; }
		if (exists(TOPFILE)==0) { return 1; }
		CMD="date '+%y%m%d' -r " TOPFILE;
		CMD | getline; DT=$0;
		TOPFILEDT=TOP "/" ARG[2] "." DT
		printf "do_cp %s\t%s.%s\t%s.%smod\n",ARG[2],ARG[2],DT,ARG[2],DT1;
		#if (exists(TOPFILEDT)==1) { printf "# %s skip cp\n",TOPFILEDT; return 0; }
		if (exists(TOPFILEDT)==1) { return 0; }
		if (DT==DT1) { CMD="cp -p " TOPFILE " " TOPFILEDT1; print CMD > stderr; system(CMD); }
		return 0;
	}
	BEGIN			{ stderr="/dev/stderr"; st=1 }
	st==1 && /^MYNAME=/	{ L=$0; sub(DT0, DT1, L); print L; st=2; next }
	st==2 && /^usage/	{ L=$0; print L; st=3; next }
	st==3 && /^do_cp /	{ L=$0; update(L); next }
	st==3			{ L=$0; gsub(DT0, DT1, L); print L; next }
				{ L=$0; print L; next }
	' - > $NAMEBASE$DT1${MYEXT}.sh

	msg "$NAMEBASE$DT1${MYEXT}.sh created"
}

usage()
{
	echo "usage: $MYNAME [-h][-v][-n][-nd][-ncp] chk|chkmod|chkmod2|chkmod12|master|mod|mod2|diff [DT]|mk [DT]|new [DT]"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -v|--verbose ... increase verbose message level"
	echo "  -n|--noexec ... no execution, test mode (FALSE)"
	echo "  -nd|--nodie ... no die (FALSE)"
	echo "  -ncp|--nocopy ... no copy (FALSE)"
	echo "  chk ... diff master"
	echo "  chkmod ... diff mod"
	echo "  chkmod2 ... diff mod2"
	echo "  chkmod12 ... diff mod mod2"
	echo "  master ... cp master files on 240121"
	echo "  mod ... cp mod files on 240121"
	echo "  mod2 ... cp mod2 files on 240121"
	echo "  diff [DT] ... diff old and new, new on DT only if set DT"
	echo "  mk [DT] ... create new shell script"
	echo "  new [DT] ... show new files since DT"
}

###
if [ x"$1" = x -o x"$1" = "x-h" ]; then
	usage
	exit $ERR_USAGE
fi

ALLOPT="$*"
OPTLOOP=$RET_TRUE
while [ $OPTLOOP -eq $RET_TRUE ];
do
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)   VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)    NOEXEC=$RET_TRUE;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

ORGCMD="$1"
CMD="$1"
OPT="$2"
msg "CMD: $CMD"
msg "OPT: $OPT"

if [ $CMD = "mk" ]; then
	DT0=`echo $MYNAME | sed -e 's/'$NAMEBASE'//' -e 's/${MYEXT}.sh//'`
	DT1=`date '+%y%m%d'`
	# overwrite
	if [ ! x"$OPT" = x ]; then
		DT1="$OPT"
	fi
	msg "DT0: $DT0  DT1: $DT1"
	do_mk $DT0 $DT1
	exit $RET_OK
fi
if [ $CMD = "new" ]; then
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt.1223
	#-rw-r--r-- 1 user user 5898 Oct  1 04:40 ggml/README.md
	DT1=`date '+%y%m%d'`
	#NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][01][0-9][0-3][0-9]\)/\2/'`
	#find $TOPDIR -type f -mtime 0 -exec ls -l '{}' \; | awk -v DT1=$DT1 '
	find $TOPDIR -type f -mtime 0 | awk -v DT1=$DT1 '
	BEGIN { PREV="" }
	#{ print "line: ",$0; }
	#{ ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	#END { ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	{ ADDDT=PREV "." DT1; if (ADDDT==$0) { PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	END { ADDDT=PREV "." DT1; if (ADDDT==$0) { ; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	' -
	exit $RET_OK
fi


###
if [ ! -d $TOPDIR ]; then
	die $ERR_NOTEXISTED "no $TOPDIR, exit"
fi
cd $TOPDIR

msg "git branch"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git branch
fi

# check:  ls -l target origin modified
# revert: cp -p origin target
# revise: cp -p modifid target
#
# do_cp target origin(master) modified(gq)
do_cp CMakeLists.txt	CMakeLists.txt.240120	CMakeLists.txt.240225mod
do_cp src/CMakeLists.txt	src/CMakeLists.txt.240203	src/CMakeLists.txt.240225mod
do_cp src/ggml.c	src/ggml.c.240203	src/ggml.c.240225mod
do_cp src/ggml-alloc.c	src/ggml-alloc.c.240203	src/ggml-alloc.c.240225mod
do_cp src/ggml-backend-impl.h	src/ggml-backend-impl.h.240203	src/ggml-backend-impl.h.240225mod
do_cp src/ggml-backend.c	src/ggml-backend.c.240203	src/ggml-backend.c.240225mod
do_cp src/ggml-impl.h	src/ggml-impl.h.240120	src/ggml-impl.h.240225mod
do_cp src/ggml-quants.h	src/ggml-quants.h.240203	src/ggml-quants.h.240225mod
do_cp src/ggml-quants.c	src/ggml-quants.c.240203	src/ggml-quants.c.240225mod
do_cp include/ggml/ggml.h	include/ggml/ggml.h.240203	include/ggml/ggml.h.240225mod
#do_cp src/ggml-opencl.c	src/ggml-opencl.c.230521	src/ggml-opencl.c.240121mod
do_cp src/ggml-opencl.cpp	src/ggml-opencl.cpp.240203	src/ggml-opencl.cpp.240225mod
do_cp src/ggml-opencl.h	src/ggml-opencl.h.240203	src/ggml-opencl.h.240225mod
do_cp tests/CMakeLists.txt	tests/CMakeLists.txt.240120	tests/CMakeLists.txt.240225mod
do_cp tests/test-blas0.c	tests/test-blas0.c.240120	tests/test-blas0.c.240225mod
# do_cp tests/test-grad0.c	tests/test-grad0.c.230730	tests/test-grad0.c.230811mod
do_cp tests/test-grad0.cpp	tests/test-grad0.cpp.240120	tests/test-grad0.cpp.240225mod
do_cp tests/test-mul-mat0.c	tests/test-mul-mat0.c.240120	tests/test-mul-mat0.c.240225mod
do_cp tests/test-mul-mat1.c	tests/test-mul-mat1.c.240120	tests/test-mul-mat1.c.240225mod
do_cp tests/test-mul-mat2.c	tests/test-mul-mat2.c.240120	tests/test-mul-mat2.c.240225mod
# do_cp tests/test-opt.c	tests/test-opt.c.230730	tests/test-opt.c.230811mod
do_cp tests/test-opt.cpp	tests/test-opt.cpp.240120	tests/test-opt.cpp.240225mod
do_cp tests/test-pool.c	tests/test-pool.c.240120	tests/test-pool.c.240225mod
do_cp tests/test-quantize-fns.cpp	tests/test-quantize-fns.cpp.240203	tests/test-quantize-fns.cpp.240225mod
do_cp tests/test-quantize-perf.cpp	tests/test-quantize-perf.cpp.240203	tests/test-quantize-perf.cpp.240225mod
do_cp tests/test-vec1.c	tests/test-vec1.c.240120	tests/test-vec1.c.240225mod
do_cp tests/test-vec2.c	tests/test-vec2.c.240120	tests/test-vec2.c.240225mod
do_cp tests/test0.c	tests/test0.c.240120	tests/test0.c.240225mod
do_cp tests/test1.c	tests/test1.c.240120	tests/test1.c.240225mod
do_cp tests/test2.c	tests/test2.c.240120	tests/test2.c.240225mod
do_cp tests/test3.c	tests/test3.c.240120	tests/test3.c.240225mod
#do_cp examples/utils.cpp    examples/utils.cpp.240121    examples/utils.cpp.240121
#do_cp examples/utils.h      examples/utils.h.240121      examples/utils.h.240121
do_cp examples/CMakeLists.txt	examples/CMakeLists.txt.240120	examples/CMakeLists.txt.240225mod
do_cp examples/common.cpp	examples/common.cpp.240203	examples/common.cpp.240225mod
do_cp examples/common.h	examples/common.h.240203	examples/common.h.240225mod
do_cp examples/common-ggml.cpp	examples/common-ggml.cpp.240120	examples/common-ggml.cpp.240225mod
do_cp examples/common-ggml.h	examples/common-ggml.h.240120	examples/common-ggml.h.240225mod
do_cp examples/whisper/CMakeLists.txt	examples/whisper/CMakeLists.txt.240120	examples/whisper/CMakeLists.txt.240225mod
do_cp examples/whisper/main.cpp	examples/whisper/main.cpp.240120	examples/whisper/main.cpp.240225mod
do_cp examples/whisper/whisper.cpp	examples/whisper/whisper.cpp.240120	examples/whisper/whisper.cpp.240225mod
do_cp examples/whisper/whisper.h	examples/whisper/whisper.h.240120	examples/whisper/whisper.h.240225mod
do_cp examples/whisper/quantize.cpp	examples/whisper/quantize.cpp.240120	examples/whisper/quantize.cpp.240225mod
do_cp examples/gpt-j/CMakeLists.txt	examples/gpt-j/CMakeLists.txt.240120	examples/gpt-j/CMakeLists.txt.240225mod
do_cp examples/gpt-j/main.cpp	examples/gpt-j/main.cpp.240120	examples/gpt-j/main.cpp.240225mod
do_cp examples/gpt-j/quantize.cpp	examples/gpt-j/quantize.cpp.240120	examples/gpt-j/quantize.cpp.240225mod
do_cp examples/gpt-2/CMakeLists.txt	examples/gpt-2/CMakeLists.txt.240120	examples/gpt-2/CMakeLists.txt.240225mod
do_cp examples/gpt-2/main.cpp	examples/gpt-2/main.cpp.240120	examples/gpt-2/main.cpp.240225mod
do_cp examples/gpt-2/main-alloc.cpp	examples/gpt-2/main-alloc.cpp.240120	examples/gpt-2/main-alloc.cpp.240225mod
do_cp examples/gpt-2/main-ctx.cpp	examples/gpt-2/main-ctx.cpp.240120	examples/gpt-2/main-ctx.cpp.240225mod
do_cp examples/gpt-2/main-backend.cpp	examples/gpt-2/main-backend.cpp.240120	examples/gpt-2/main-backend.cpp.240225mod
do_cp examples/gpt-2/main-batched.cpp	examples/gpt-2/main-batched.cpp.240120	examples/gpt-2/main-batched.cpp.240225mod
do_cp examples/gpt-2/quantize.cpp	examples/gpt-2/quantize.cpp.240120	examples/gpt-2/quantize.cpp.240225mod
msg "RESULT: $RESULT"

if [ $CMD = "chk" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for zipping, syncing"
	else
		emsg "do $MYNAME chkmod and $MYNAME master before zipping, syncing"
	fi
fi
if [ $CMD = "chkmod" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		emsg "save files and update $MYNAME"
	fi
fi
if [ $CMD = "chkmod2" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		emsg "save files and update $MYNAME"
	fi
fi

# cmake .. -DGGML_OPENBLAS=ON
# make test-blas0 test-grad0 test-mul-mat0 test-mul-mat2 test-svd0 test-vec0 test-vec1 test0 test1 test2 test3
# GGML_NLOOP=1 GGML_NTHREADS=4 make test
msg "end"
