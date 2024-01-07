#!/bin/sh

MYNAME=fix1223.sh

TOPDIR=ggml
NAMEBASE=fix

CMD=chk

###
msg()
{
	echo "$MYNAME: $*"
}

###
#do_cp ggml.c	ggml.c.1001	ggml.c.1001mod

# diff old $1 $2 $OPT
diff_old()
{
	#msg "do_diff_old CMD:$CMD $1 $2 $3 $4  OPT:$OPT"
	# in $TOPDIR

	if [ ! x"$OPT" = x ]; then
		NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
		#msg "diff: NEW:$NEWDATE"
		if [ ! x"$NEWDATE" = x"$OPT" ]; then
			msg "diff: skip $2 by $NEWDATE"
			return
		fi
	fi

	#msg "diff_old $1 $2"
	NEW="./$2"
	OLD=`find . -path './'$1'.[0-9][0-9][0-9][0-9]' | awk -v NEW="$NEW" '
	$0 != NEW { OLD=$0 }
	END   { print OLD }'`
	msg "diff -c $OLD $NEW"
	diff -c $OLD $NEW
}

# do_cp target origin modified
do_cp()
{
	#msg "do_cp CMD:$CMD $1 $2 $3 $4"

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
			msg "diff -c $2 $1"
			diff -c $2 $1
			#msg "RESULT: $RESULT $?"
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod|checkmod|chkgq|checkgq)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ -f $3 ]; then
			msg "diff -c $1 $3"
			diff -c $1 $3
			RESULT=`expr $RESULT + $?`
		fi
		;;
	chkmod2|checkmod2|gqmod|checkgqmod)
		msg "ls -l $FILES"
		ls -l $FILES
		if [ $# = 4 ]; then
			if [ -f $4 ]; then
				msg "diff -c $1 $4"
				diff -c $1 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "diff -c $1 $3"
				diff -c $1 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "diff -c $1 $3"
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
				msg "diff -c $3 $4"
				diff -c $3 $4
				RESULT=`expr $RESULT + $?`
			elif [ -f $3 ]; then
				msg "diff -c $2 $3"
				diff -c $2 $3
				RESULT=`expr $RESULT + $?`
			fi
		else
			if [ -f $3 ]; then
				msg "diff -c $2 $3"
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
		diff_old $1 $2
		;;
	*)	msg "unknown command: $CMD"
		;;
	esac
}

do_mk()
{
	msg "making new fix script $NAMEBASE$DT1.sh and copy backup files ..."

#do_cp ggml.c		  ggml.c.0420		  ggml.c.0420mod    ggml.c.0420mod2
#do_cp examples/CMakeLists.txt examples/CMakeLists.txt.0413 examples/CMakeLists.txt.0415mod
#do_cp examples/benchmark/benchmark-q4_0-matmult.cpp	examples/benchmark/benchmark-q4_0-matmult.c.0417	examples/benchmark/benchmark-q4_0-matmult.cpp.0417mod	examples/benchmark/benchmark-q4_0-matmult.cpp.0423mod
	cat $MYNAME | awk -v DT0=$DT0 -v DT1=$DT1 -v TOP="$TOPDIR" '
	function exists(file) {
		n=(getline _ < file);
		if (n > 0) {
			return 1; # found
		} else if (n == 0) {
			return 1; # empty
		} else {
			return 0; # error
		}
		return 0; # error
	}
	function update(L) {
		NARG=split(L, ARG, /[ \t]/);
		TOPFILE=TOP "/" ARG[2]
		TOPFILEDT1=TOP "/" ARG[2] "." DT1
		if (exists(TOPFILE)==0) { printf "# %s\n",L; return 1; }
		CMD="date '+%m%d' -r " TOPFILE;
		CMD | getline; DT=$0;
		TOPFILEDT=TOP "/" ARG[2] "." DT
		printf "do_cp %s\t%s.%s\t%s.%smod\n",ARG[2],ARG[2],DT,ARG[2],DT1;
		if (exists(TOPFILEDT)==1) { printf "# %s skip cp\n",TOPFILEDT; return 0; }
		if (DT==DT1) { CMD="cp -p " TOPFILE " " TOPFILEDT1; print CMD > stderr; system(CMD); }
	}
	BEGIN		{ stderr="/dev/stderr"; st=1 }
	st==1 && /^MYNAME=/	{ L=$0; sub(DT0, DT1, L); print L; st=2; next }
	st==2 && /^usage/	{ L=$0; print L; st=3; next }
	st==3 && /^do_cp /	{ L=$0; update(L); next }
	st==3			{ L=$0; gsub(DT0, DT1, L); print L; next }
				{ L=$0; print L; next }
	' - > $NAMEBASE$DT1.sh

	msg "$NAMEBASE$DT1.sh created"
}

usage()
{
	echo "usage: $MYNAME [-h] chk|chkmod|chkmod2|checkmod12|master|mod|mod2|diff|mk|new [DT]"
	echo "-h ... this help message"
	echo "chk ... diff master"
	echo "chkmod ... diff mod"
	echo "chkmod2 ... diff mod2"
	echo "chkmod12 ... diff mod mod2"
	echo "master ... cp master files on 1223"
	echo "mod ... cp mod files on 1223"
	echo "mod2 ... cp mod2 files on 1223"
	echo "diff [DT] ... diff old and new, new on DT only if set DT"
	echo "mk [DT] ... create new shell script"
	echo "new [DT] ... show new files since DT"
}

###
if [ x"$1" = x -o x"$1" = "x-h" ]; then
	usage
	exit 1
fi
ORGCMD="$1"
CMD="$1"
OPT="$2"
msg "CMD: $CMD"
msg "OPT: $OPT"

if [ $CMD = "mk" ]; then
	DT0=`echo $MYNAME | sed -e 's/'$NAMEBASE'//' -e 's/.sh//'`
	DT1=`date '+%m%d'`
	# overwrite
	if [ ! x"$OPT" = x ]; then
		DT1="$OPT"
	fi
	msg "DT0: $DT0  DT1: $DT1"
	do_mk $DT0 $DT1
	exit 0
fi
if [ $CMD = "new" ]; then
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt
	#-rw-r--r-- 1 user user 6512 Oct  1 04:40 ggml/CMakeLists.txt.1223
	#-rw-r--r-- 1 user user 5898 Oct  1 04:40 ggml/README.md
	DT1=`date '+%m%d'`
	#NEWDATE=`echo $2 | sed -e 's/\(.*\)\.\([0-9][0-9][0-9][0-9]\)/\2/'`
	#find $TOPDIR -type f -mtime 0 -exec ls -l '{}' \; | awk -v DT1=$DT1 '
	find $TOPDIR -type f -mtime 0 | awk -v DT1=$DT1 '
	BEGIN { PREV="" }
	#{ print "line: ",$0; }
	#{ ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	#END { ADDDT=PREV "." DT1; if (ADDDT==$0) { print "same: ",$0; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	{ ADDDT=PREV "." DT1; if (ADDDT==$0) { PREV="" } else if (PREV=="") { PREV=$0 } else { print "new: ",PREV; PREV=$0 } }
	END { ADDDT=PREV "." DT1; if (ADDDT==$0) { ; } else if (PREV=="") { ; } else { print "new: ",PREV; } }
	' -
	exit 0
fi

###
#cd ~/github/gpt/$TOPDIR
if [ ! -d $TOPDIR ]; then
	msg "no $TOPDIR, exit"
	exit 3
fi
cd $TOPDIR

msg "git branch"
git branch

# check:  ls -l target origin modified
# revert: cp -p origin target
# revise: cp -p modifid target
#
# do_cp target origin(master) modified(gq)
RESULT=0
do_cp CMakeLists.txt	CMakeLists.txt.1223	CMakeLists.txt.1223mod
# ggml/CMakeLists.txt.1223 skip cp
# ggml/CMakeLists.txt.1111 skip cp
do_cp src/CMakeLists.txt	src/CMakeLists.txt.1223	src/CMakeLists.txt.1223mod
# ggml/src/CMakeLists.txt.1223 skip cp
do_cp src/ggml.c	src/ggml.c.1223	src/ggml.c.1223mod
# ggml/src/ggml.c.1223 skip cp
do_cp src/ggml-alloc.c	src/ggml-alloc.c.1223	src/ggml-alloc.c.1223mod
# ggml/src/ggml-alloc.c.1223 skip cp
do_cp src/ggml-backend-impl.h	src/ggml-backend-impl.h.1223	src/ggml-backend-impl.h.1223mod
# ggml/src/ggml-backend-impl.h.1223 skip cp
do_cp src/ggml-backend.c	src/ggml-backend.c.1223	src/ggml-backend.c.1223mod
# ggml/src/ggml-backend.c.1223 skip cp
do_cp src/ggml-impl.h	src/ggml-impl.h.1223	src/ggml-impl.h.1223mod
# ggml/src/ggml-impl.h.1223 skip cp
do_cp src/ggml-quants.h	src/ggml-quants.h.1223	src/ggml-quants.h.1223mod
# ggml/src/ggml-quants.h.1223 skip cp
do_cp src/ggml-quants.c	src/ggml-quants.c.1223	src/ggml-quants.c.1223mod
# ggml/src/ggml-quants.c.1223 skip cp
do_cp include/ggml/ggml.h	include/ggml/ggml.h.1223	include/ggml/ggml.h.1223mod
# ggml/include/ggml/ggml.h.1223 skip cp
#do_cp src/ggml-opencl.c	src/ggml-opencl.c.0521	src/ggml-opencl.c.1223mod
do_cp src/ggml-opencl.cpp	src/ggml-opencl.cpp.1223	src/ggml-opencl.cpp.1223mod
# ggml/src/ggml-opencl.cpp.1223 skip cp
do_cp src/ggml-opencl.h	src/ggml-opencl.h.0701	src/ggml-opencl.h.1223mod
# ggml/src/ggml-opencl.h.0701 skip cp
do_cp tests/CMakeLists.txt	tests/CMakeLists.txt.1223	tests/CMakeLists.txt.1223mod
# ggml/tests/CMakeLists.txt.1223 skip cp
do_cp tests/test-blas0.c	tests/test-blas0.c.1223	tests/test-blas0.c.1223mod
# ggml/tests/test-blas0.c.1223 skip cp
# ggml/tests/test-blas0.c.1111 skip cp
# do_cp tests/test-grad0.c	tests/test-grad0.c.0730	tests/test-grad0.c.0811mod
do_cp tests/test-grad0.cpp	tests/test-grad0.cpp.1223	tests/test-grad0.cpp.1223mod
# ggml/tests/test-grad0.cpp.1223 skip cp
do_cp tests/test-mul-mat0.c	tests/test-mul-mat0.c.1223	tests/test-mul-mat0.c.1223mod
# ggml/tests/test-mul-mat0.c.1223 skip cp
do_cp tests/test-mul-mat1.c	tests/test-mul-mat1.c.1223	tests/test-mul-mat1.c.1223mod
# ggml/tests/test-mul-mat1.c.1223 skip cp
do_cp tests/test-mul-mat2.c	tests/test-mul-mat2.c.1001	tests/test-mul-mat2.c.1223mod
# ggml/tests/test-mul-mat2.c.1001 skip cp
# do_cp tests/test-opt.c	tests/test-opt.c.0730	tests/test-opt.c.0811mod
do_cp tests/test-opt.cpp	tests/test-opt.cpp.1223	tests/test-opt.cpp.1223mod
# ggml/tests/test-opt.cpp.1223 skip cp
do_cp tests/test-pool.c	tests/test-pool.c.1223	tests/test-pool.c.1223mod
# ggml/tests/test-pool.c.1223 skip cp
do_cp tests/test-quantize-fns.cpp	tests/test-quantize-fns.cpp.1223	tests/test-quantize-fns.cpp.1223mod
# ggml/tests/test-quantize-fns.cpp.1223 skip cp
do_cp tests/test-quantize-perf.cpp	tests/test-quantize-perf.cpp.1223	tests/test-quantize-perf.cpp.1223mod
# ggml/tests/test-quantize-perf.cpp.1223 skip cp
do_cp tests/test-vec1.c	tests/test-vec1.c.1001	tests/test-vec1.c.1223mod
# ggml/tests/test-vec1.c.1001 skip cp
do_cp tests/test-vec2.c	tests/test-vec2.c.1223	tests/test-vec2.c.1223mod
# ggml/tests/test-vec2.c.1223 skip cp
do_cp tests/test0.c	tests/test0.c.1223	tests/test0.c.1223mod
# ggml/tests/test0.c.1223 skip cp
do_cp tests/test1.c	tests/test1.c.1223	tests/test1.c.1223mod
# ggml/tests/test1.c.1223 skip cp
do_cp tests/test2.c	tests/test2.c.0701	tests/test2.c.1223mod
# ggml/tests/test2.c.0701 skip cp
do_cp tests/test3.c	tests/test3.c.0701	tests/test3.c.1223mod
# ggml/tests/test3.c.0701 skip cp
#do_cp examples/utils.cpp    examples/utils.cpp.1223    examples/utils.cpp.1223
#do_cp examples/utils.h      examples/utils.h.1223      examples/utils.h.1223
do_cp examples/CMakeLists.txt	examples/CMakeLists.txt.1223	examples/CMakeLists.txt.1223mod
# ggml/examples/CMakeLists.txt.1223 skip cp
do_cp examples/common.cpp	examples/common.cpp.1223	examples/common.cpp.1223mod
# ggml/examples/common.cpp.1223 skip cp
do_cp examples/common.h	examples/common.h.1223	examples/common.h.1223mod
# ggml/examples/common.h.1223 skip cp
do_cp examples/common-ggml.cpp	examples/common-ggml.cpp.1223	examples/common-ggml.cpp.1223mod
# ggml/examples/common-ggml.cpp.1223 skip cp
do_cp examples/common-ggml.h	examples/common-ggml.h.0521	examples/common-ggml.h.1223mod
# ggml/examples/common-ggml.h.0521 skip cp
do_cp examples/whisper/CMakeLists.txt	examples/whisper/CMakeLists.txt.1223	examples/whisper/CMakeLists.txt.1223mod
# ggml/examples/whisper/CMakeLists.txt.1223 skip cp
do_cp examples/whisper/main.cpp	examples/whisper/main.cpp.1223	examples/whisper/main.cpp.1223mod
# ggml/examples/whisper/main.cpp.1223 skip cp
do_cp examples/whisper/whisper.cpp	examples/whisper/whisper.cpp.1223	examples/whisper/whisper.cpp.1223mod
# ggml/examples/whisper/whisper.cpp.1223 skip cp
do_cp examples/whisper/whisper.h	examples/whisper/whisper.h.1223	examples/whisper/whisper.h.1223mod
# ggml/examples/whisper/whisper.h.1223 skip cp
do_cp examples/whisper/quantize.cpp	examples/whisper/quantize.cpp.1001	examples/whisper/quantize.cpp.1223mod
# ggml/examples/whisper/quantize.cpp.1001 skip cp
do_cp examples/gpt-j/CMakeLists.txt	examples/gpt-j/CMakeLists.txt.0521	examples/gpt-j/CMakeLists.txt.1223mod
# ggml/examples/gpt-j/CMakeLists.txt.0521 skip cp
do_cp examples/gpt-j/main.cpp	examples/gpt-j/main.cpp.1223	examples/gpt-j/main.cpp.1223mod
# ggml/examples/gpt-j/main.cpp.1223 skip cp
do_cp examples/gpt-j/quantize.cpp	examples/gpt-j/quantize.cpp.0715	examples/gpt-j/quantize.cpp.1223mod
# ggml/examples/gpt-j/quantize.cpp.0715 skip cp
do_cp examples/gpt-2/CMakeLists.txt	examples/gpt-2/CMakeLists.txt.1223	examples/gpt-2/CMakeLists.txt.1223mod
# ggml/examples/gpt-2/CMakeLists.txt.1223 skip cp
do_cp examples/gpt-2/main.cpp	examples/gpt-2/main.cpp.1223	examples/gpt-2/main.cpp.1223mod
# ggml/examples/gpt-2/main.cpp.1223 skip cp
do_cp examples/gpt-2/main-alloc.cpp	examples/gpt-2/main-alloc.cpp.1223	examples/gpt-2/main-alloc.cpp.1223mod
# ggml/examples/gpt-2/main-alloc.cpp.1223 skip cp
do_cp examples/gpt-2/main-ctx.cpp	examples/gpt-2/main-ctx.cpp.1223	examples/gpt-2/main-ctx.cpp.1223mod
# ggml/examples/gpt-2/main-ctx.cpp.1223 skip cp
do_cp examples/gpt-2/main-backend.cpp	examples/gpt-2/main-backend.cpp.1223	examples/gpt-2/main-backend.cpp.1223mod
# ggml/examples/gpt-2/main-backend.cpp.1223 skip cp
do_cp examples/gpt-2/main-batched.cpp	examples/gpt-2/main-batched.cpp.1223	examples/gpt-2/main-batched.cpp.1223mod
# ggml/examples/gpt-2/main-batched.cpp.1223 skip cp
do_cp examples/gpt-2/quantize.cpp	examples/gpt-2/quantize.cpp.0715	examples/gpt-2/quantize.cpp.1223mod
# ggml/examples/gpt-2/quantize.cpp.0715 skip cp
msg "RESULT: $RESULT"

if [ $CMD = "chk" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for zipping, syncing"
	else
		msg "do $MYNAME chkmod and $MYNAME master before zipping, syncing"
	fi
fi
if [ $CMD = "chkmod" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "save files and update $MYNAME"
	fi
fi
if [ $CMD = "chkmod2" ];then
	if [ $RESULT -eq 0 ]; then
		msg "ok for do $MYNAME master and then zipping, syncing"
	else
		msg "save files and update $MYNAME"
	fi
fi

# cmake .. -DGGML_OPENBLAS=ON
# make test-blas0 test-grad0 test-mul-mat0 test-mul-mat2 test-svd0 test-vec0 test-vec1 test0 test1 test2 test3
# GGML_NLOOP=1 GGML_NTHREADS=4 make test
msg "end"
