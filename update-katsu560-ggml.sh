#!/bin/sh

# update katsu560/ggml
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-ggml.sh

# common code, functions
### return code/error code
RET_TRUE=1              # TRUE
RET_FALSE=0             # FALSE
RET_OK=0                # OK
RET_NG=1                # NG
RET_YES=1               # YES
RET_NO=0                # NO
RET_CANCEL=2            # CANCEL

ERR_USAGE=1             # usage
ERR_UNKNOWN=2           # unknown error
ERR_NOARG=3             # no argument
ERR_BADARG=4            # bad argument
ERR_NOTEXISTED=10       # not existed
ERR_EXISTED=11          # already existed
ERR_NOTFILE=12          # not file
ERR_NOTDIR=13           # not dir
ERR_CANTCREATE=14       # can't create
ERR_CANTOPEN=15         # can't open
ERR_CANTCOPY=16         # can't copy
ERR_CANTDEL=17          # can't delete

# set unique return code from 100
ERR_NOTOPDIR=100        # no topdir
ERR_NOBUILDDIR=101      # no build dir


### flags
VERBOSE=0               # -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE       # -n --noexec flag
FORCE=$RET_FALSE        # -f --force flag
NODIE=$RET_FALSE        # -nd --nodie
NOCOPY=$RET_FALSE       # -ncp --nocopy
NOTHING=

###
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
# https://qiita.com/PruneMazui/items/8a023347772620025ad6
# https://stackoverflow.com/questions/4842424/list-of-ansi-color-escape-sequences
ESC=$(printf '\033')
ESCRESET="${ESC}[0m"
ESCBOLD="${ESC}[1m"
ESCFAINT="${ESC}[2m"
ESCITALIC="${ESC}[3m"
ESCUL="${ESC}[4m"	# underline
ESCBLINK="${ESC}[5m"	# slow blink
ESCRBLINK="${ESC}[6m"	# rapid blink
ESCREVERSE="${ESC}[7m"
ESCCONCEAL="${ESC}[8m"
ESCDELETED="${ESC}[9m"	# crossed-out
ESCBOLDOFF="${ESC}[22m"	# bold off, faint off
ESCITALICOFF="${ESC}[23m"  # italic off
ESCULOFF="${ESC}[24m"	# underline off
ESCBLINKOFF="${ESC}[25m"   # blink off
ESCREVERSEOFF="${ESC}[27m" # reverse off
ESCCONCEALOFF="${ESC}[28m" # conceal off
ESCDELETEDOFF="${ESC}[29m" # deleted off
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

ESCOK="$ESCGREEN"
ESCERR="$ESCRED"
ESCWARN="$ESCMAGENTA"
ESCINFO="$ESCWHITE"

xxmsg()
{
	if [ $VERBOSE -ge 2 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

xmsg()
{
	if [ $VERBOSE -ge 1 ]; then
		echo "$MYNAME: $*" 1>&2
	fi
}

emsg()
{
        echo "${ESCERR}$MYNAME: $*${ESCBACK}" 1>&2
}

msg()
{
	echo "$MYNAME: $*"
}

die()
{
	local CODE

	CODE=$1
	shift
	xxmsg "die: CODE:$CODE msg:$*"

        msg "${ESCERR}$*${ESCBACK}"
	if [ $NODIE -eq $RET_TRUE ]; then
		xmsg "die: nodie"
		return
	fi
	exit $CODE
}

nothing()
{
	NOTHING=
}

# for test code
func_test()
{
	RETCODE=$?

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		msg "${ESCOK}test:OK${ESCBACK}: ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		msg "${ESCERR}${ESCBOLD}test:NG${ESCBOLDOFF}${ESCBACK}: ret:$RETCODE expected:$OKCODE ${ESCRED}$TESTMSG${ESCBACK}"
	fi
	msg "----"
}

# for test code
set_ret()
{
	return $1
}


chk_and_cp()
{
	local chkfiles cpopt narg argfiles dstpath ncp cpfiles i

	#xmsg "----"
	#xmsg "chk_and_cp: $*"
	#xmsg "chk_and_cp: nargs:$# args:$*"
	if [ $# -eq 0 ]; then
		msg "${ESCERR}chk_and_cp: ARG:$*: no cpopt, chkfiles${ESCBACK}"
		return $ERR_NOARG
	fi

	# get cp opt
	cpopt=$1
	shift
	#xmsg "chk_and_cp: narg:$# args:$*"

	if [ $# -le 1 ]; then
		msg "${ESCERR}chk_and_cp: CPOPT:$cpopt ARG:$*: bad arg, not enough${ESCBACK}"
		return $ERR_BADARG
	fi

	narg=$#
	dstpath=`eval echo '${'$#'}'`
	#xmsg "chk_and_cp: narg:$# dstpath:$dstpath"
	if [ ! -d $dstpath ]; then
		dstpath=
	fi
	argfiles="$*"
	#xmsg "chk_and_cp: cpopt:$cpopt narg:$narg argfiles:$argfiles dstpath:$dstpath"

	ncp=1
	cpfiles=
	for i in $argfiles
	do
		#xmsg "chk_and_cp: ncp:$ncp/$narg i:$i"
		if [ $ncp -eq $narg ]; then
			dstpath="$i"
			break
		fi

		if [ -f $i ]; then
			cpfiles="$cpfiles $i"
		elif [ -d $i -a ! "x$i" = x"$dstpath" ]; then
			cpfiles="$cpfiles $i"
		else
			msg "${ESCWARN}chk_and_cp: $i: can't add to cpfiles, ignore${ESCBACK}"
			msg "ls -l $i"
			ls -l $i
		fi

		ncp=`expr $ncp + 1`
	done

	#xmsg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstpath:$dstpath"
	if [ x"$cpfiles" = x ]; then
		msg "${ESCERR}chk_and_cp: bad arg, no cpfiles${ESCBACK}"
		return $ERR_BADARG
	fi

	if [ x"$dstpath" = x ]; then
		msg "${ESCERR}chk_and_cp: bad arg, no dstpath${ESCBACK}"
		return $ERR_BADARG
	fi

	if [ $ncp -eq 2 ]; then
		if [ -f $cpfiles -a ! -e $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -f $dstpath -a $cpfiles = $dstpath ]; then
			msg "${ESCERR}chk_and_cp: bad arg, same file${ESCBACK}"
			return $ERR_BADARG
		elif [ -d $cpfiles -a -f $dstpath ]; then
			msg "${ESCERR}chk_and_cp: bad arg, dir to file${ESCBACK}"
			return $ERR_BADARG
		elif [ -f $cpfiles -a -f $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -d $dstpath ]; then
			nothing
		fi
	elif [ ! -e $dstpath ]; then
		msg "${ESCERR}chk_and_cp: not existed${ESCBACK}"
		return $ERR_NOTEXISTED
	elif [ ! -d $dstpath ]; then
		msg "${ESCERR}chk_and_cp: not dir${ESCBACK}"
		return $ERR_NOTDIR
	fi

	if [ $NOEXEC -eq $RET_FALSE ]; then
		msg "cp $cpopt $cpfiles $dstpath"
		cp $cpopt $cpfiles $dstpath || return $?
	else
		msg "${ESCWARN}noexec: cp $cpopt $cpfiles $dstpath${ESCBACK}"
	fi

	return $RET_OK
}
test_chk_and_cp()
{
	# test files and dir, test-no.$$, testdir-no.$$: not existed
	touch test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$
	rm test-no.$$
	mkdir testdir.$$
	rmdir testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"

	# test code
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp
	func_test $ERR_NOARG "no cpopt: chk_and_cp"

	chk_and_cp -p
	func_test $ERR_BADARG "bad arg: chk_and_cp -p"

	chk_and_cp -p test-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$"
	chk_and_cp -p test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test.$$"
	chk_and_cp -p testdir-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p testdir-no.$$"
	chk_and_cp -p testdir.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p testdir.$$"

	chk_and_cp -p test-no.$$ test-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ test-no.$$"
	chk_and_cp -p test-no.$$ test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ test.$$"
	chk_and_cp -p test-no.$$ testdir-no.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ testdir-no.$$"
	chk_and_cp -p test-no.$$ testdir.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test-no.$$ testdir.$$"

	chk_and_cp -p test.$$ test-no.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$"
	msg "ls test-no.$$"; ls -l test-no.$$; rm -rf test-no.$$
	chk_and_cp -p test.$$ test-1.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$"
	msg "ls test-1.$$"; ls -l test-1.$$
	chk_and_cp -p test.$$ test.$$
	func_test $ERR_BADARG "bad arg: chk_and_cp -p test.$$ test.$$"
	chk_and_cp -p test.$$ testdir-no.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$"
	msg "ls testdir-no.$$"; ls -l testdir-no.$$; rm -rf testdir-no.$$
	chk_and_cp -p test.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-no.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-no.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir-no.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir-no.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ testdir.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ testdir.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$

	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$
	chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$
	func_test $RET_OK "ok: chk_and_cp -p test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ testdir.$$"
	msg "ls testdir.$$"; ls -l testdir.$$; rm -rf testdir.$$; mkdir testdir.$$


	rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$
	rm -rf testdir.$$ testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
}
#msg "test_chk_and_cp"; VERBOSE=1; test_chk_and_cp; exit 0


###
TOPDIR=ggml
BASEDIR=~/github/$TOPDIR
BUILDPATH="$TOPDIR/build"
# script
SCRIPT=script
FIXBASE="fix"
SCRIPTNAME=ggml
UPDATENAME=update-katsu560-${SCRIPTNAME}.sh
FIXSHNAME=${FIXBASE}[0-9][0-9][0-9][0-9].sh
MKZIPNAME=mkzip-${SCRIPTNAME}.sh

# cmake
# check OpenBLAS
OPENBLAS=`grep -sr GGML_OPENBLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*GGML_OPENBLAS.*/GGML_OPENBLAS/'`
BLAS=`grep -sr GGML_BLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*GGML_BLAS.*/GGML_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
        # CMakeLists.txt w/ GGML_OPENBLAS
        GGML_OPENBLAS="-DGGML_OPENBLAS=ON"
        BLASVENDOR=""
        msg "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
else
	GGML_OPENBLAS=
fi
if [ ! x"$BLAS" = x ]; then
        # CMakeLists.txt w/ GGML_BLAS
        GGML_OPENBLAS="-DGGML_BLAS=ON"
        BLASVENDOR="-DGGML_BLAS_VENDOR=OpenBLAS"
        msg "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
CMKOPTBLAS="$GGML_OPENBLAS $BLASVENDOR"

CMKOPTNOAVX="-DGGML_AVX=OFF -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF $CMKOPTBLAS -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTAVX="-DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=ON $CMKOPTBLAS -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTAVX2="-DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=ON -DGGML_F16C=ON $CMKOPTBLAS -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTNONE="$CMKOPTBLAS -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPT="$CMKOPTNONE"

# default -avx
#CMKOPT="$CMKOPTAVX"
CMKOPT2=""

# get targets
#　Makefile 
## Help Target
#help:
#        @echo "The following are some of the valid targets for this Makefile:"
#        @echo "... all (the default if no target is provided)"
#        @echo "... clean"
#        @echo "... depend"
#        @echo "... edit_cache"
#        @echo "... install"
#        @echo "... install/local"
#        @echo "... install/strip"
#        @echo "... list_install_components"
#        @echo "... rebuild_cache"
#        @echo "... test"
#        @echo "... common"
#        @echo "... common-ggml"
#        @echo "... dollyv2"
#        @echo "... dollyv2-quantize"
#        @echo "... ggml"
# :
#        @echo "... test-conv-transpose"
#        @echo "... test-customop"
# :
#.PHONY : help
NOBINSTEST="all clean depend edit_cache install install/local install/strip list_install_components rebuild_cache test"
NOTEST="test-blas0"
NOBINS="whisper-cpp"
NOBINSTEST="$NOBINSTEST common common-ggml ggml $NOBINS"
ALLBINS=
TESTS=
GPT2=

get_targets()
{
	local i

	if [ ! -e $BUILDPATH/Makefile ]; then
		msg "no $BUILDPATH/Makefile"
		return $ERR_NOTEXISTED
	fi

	TARGETS=`awk -v NOBINSTEST="$NOBINSTEST" '
	BEGIN { ST=0; split(NOBINSTEST,NOTGT); }
	function is_notgt(tgt) {
		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
		return 0;
	}
	ST==0 && /^help:/ { ST=1 }
	ST==1 && /^.PHONY : help/ { ST=2 }
	ST==1 && /echo .\.\.\./ { T=$0; sub(/^[^@]*.echo ...../,"",T); sub(/"$/,"",T); sub(/ .*$/,"",T);
	  if (is_notgt(T)==0) { printf("%s ",T) } }' $BUILDPATH/Makefile`
	msg "TARGETS: $TARGETS"

	TESTS=
	ALLBINS=
	for i in $TARGETS
	do
		case $i in
		test*)	TESTS="$TESTS $i";;
		gpt-2*)	GPT2="$GPT2 $i"; ALLBINS="$ALLBINS $i";;
		*)	ALLBINS="$ALLBINS $i";;
		esac
	done

	msg "ALLBINS: $ALLBINS"
	msg "TESTS: $TESTS"

	return $RET_OK
}


# for test, main, examples execution
TESTENV="GGML_NLOOP=1 GGML_NTHREADS=4"

JFKWAV=jfk.wav
NHKWAV=nhk0521-16000hz1ch-0-10s.wav

PROMPTEX="This is an example"
PROMPT="tell me about creating web site in 5 steps:"
#PROMPTJP="京都について教えてください:"
PROMPTJP="あなたは誠実で日本に詳しい観光業者です。京都について教えてください:"
SEEDOPT=
SEED=1685215400

MKCLEAN=$RET_FALSE
NOCLEAN=$RET_FALSE

###
usage()
{
	echo "usage: $MYNAME [-h][-v][-n][-nd][-ncp][-nc][-noavx|avx|avx2] dirname branch cmd"
	echo "options: (default)"
	echo "-h|--help ... this message"
	echo "-v|--verbose ... increase verbose message level"
	echo "-n|--noexec ... no execution, test mode"
	echo "-nd|--nodie ... no die"
	echo "-ncp|--nocopy ... no copy"
	echo "-nc|--noclean ... no make clean"
	#echo "-up ... upstream, no mod source, skip test-blas0"
	echo "-noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "dirname ... directory name ex. 0226up"
	echo "branch ... git branch ex. master, gq, devpr"
	echo "cmd ... sycpcmktstex sy/sync,cp/copy,cmk/cmake,tst/test,ex/examples"
	echo "cmd ... sycpcmktstne sy,cp,cmk,tst,ne  ne .. build examples but no exec"
	echo "cmd ... cpcmkg2gjwhtst cp,cmk,g2,gj,wh,gx,dl,tst gpt-2,gpt-j,whisper,gpt-neox,dollyv2"
	echo "cmd ... cpcmkn2njwhtst cp,cmk,n2,nj,nh,nx,nd,tst build gpt-j but no exec, gpt-2, ..."
	echo "cmd ... script .. push $UPDATENAME $MKZIPNAME $FIXSHNAME to remote"
}

###
if [ x"$1" = x -o $# -lt 3 ]; then
	usage
	exit $ERR_USAGE
fi

get_targets

ALLOPT="$*"
OPTLOOP=1
while [ $OPTLOOP -eq 1 ];
do
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)	VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)	NOEXEC=$RET_TRUE;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	-nc|--noclean)	NOCLEAN=$RET_TRUE;;
	#-up)		ALLBINS="$ALLBINSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	*)		OPTLOOP=$RET_FALSE; break;;
	esac
	shift
done

# default -avx|AVX
if [ x"$CMKOPT" = x"" ]; then
	CMKOPT="$CMKOPTAVX"
fi
CMKOPT="$CMKOPT $CMKOPT2"

DIRNAME="$1"
BRANCH="$2"
CMD="$3"

###

# yyyymmddHHMMSS filename
# get date and filename given FILENAME
# get_datefile FILENAME
get_datefile()
{
	local FILE

	if [ ! $# -ge 1 ]; then
		emsg "get_datefile: RETCODE:$ERR_NOARG: ARG:$*: need FILENAME, error return"
		return $ERR_NOARG
	fi

	FILE="$1"

	xmsg "get_date: FILE:$FILE ARG:$*"

	#if [ ! -f $FILE ]; then
	#	emsg "get_datefile: RETCODE:$ERR_NOTEXISTED: $FILE: not found, error return"
	#	return $ERR_NOTEXISTED
	#fi

	ls -ltr --time-style=+%Y%m%d%H%M%S $FILE | awk '
	BEGIN { XDT="0"; XNM="" }
	#{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; printf("%s %s D:%s %s\n",XDT,XNM,DT,NM) >> /dev/stderr }
	{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; }
	END { printf("%s %s\n",XDT,XNM) }
	'

	return $?
}
test_get_datefile()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1

	DF=`get_datefile`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile"

	DF=`get_datefile $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_datefile $NGFILE"
	DF=`get_datefile $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile $OKFILE"
	DF=`get_datefile $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_datefile $NGFILE2"
	DF=`get_datefile $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile $OKFILE2"

	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile"; VERBOSE=2; test_get_datefile; exit 0

# Ymd|ymd|md|full yyyymmddHHMMSS filename
# get date given YMDoption DATE FILENAME
# get_datefile_date OPT DATE FILENAME
get_datefile_date()
{
	local DTFILE

	if [ ! $# -ge 3 ]; then
		emsg "get_datefile_date: RETCODE:$ERR_NOARG: ARG:$*: need OPT DATE FILENAME, error return"
		return $ERR_NOARG
	fi

	OPT="$1"
	shift
	DTFILE="$*" # date filename

	xmsg "get_datefile_date: OPT:$OPT DTFILE:$DTFILE"

	echo $DTFILE | awk -v OPT=$OPT '{ T=$0; sub(/[\n\r]$/,"",T); D=substr(T,1,14); if (OPT=="Ymd") { print substr(D,1,8) } else if (OPT=="ymd") { print substr(D,3,6) } else if (OPT=="md") { print substr(D,5,4) } else if (OPT=="full") { print D } else { print D } }'
	return $?
}
test_get_datefile_date()
{
	local DT OKFILE NGFILE DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	ls $OKFILE $NGFILE

	DF=`get_datefile_date`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date"
	DF=`get_datefile_date md`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date md"
	DF=`get_datefile_date $DT`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $DT"
	DF=`get_datefile_date $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $OKFILE"
	DF=`get_datefile_date $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_date $DT $OKFILE"

	DF=`get_datefile_date Ymd $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date Ymd $DT $OKFILE"
	DF=`get_datefile_date ymd $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date ymd $DT $OKFILE"
	DF=`get_datefile_date md $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $OKFILE"
	DF=`get_datefile_date full $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date full $DT $OKFILE"
	DF=`get_datefile_date ngopt $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date ngopt $DT $OKFILE"
	DF=`get_datefile_date md $DT $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $NGFILE"

	DF=`get_datefile_date Ymd $DT $OKFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date Ymd $DT $OKFILE extra"
	DF=`get_datefile_date md $DT $OKFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $OKFILE extra"
	DF=`get_datefile_date md $DT $NGFILE extra`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_date md $DT $NGFILE extra"

	rm $OKFILE $NGFILE
}
#msg "test_get_datefile_date"; VERBOSE=2; test_get_datefile_date; exit 0

# yyyymmddHHMMSS filename
# get filename given DATE FILENAME
# get_datefile_file DATE FILENAME
get_datefile_file()
{
	local DTFILE

	if [ ! $# -ge 2 ]; then
		emsg "get_datefile_file: RETCODE:$ERR_NOARG: ARG:$*: need DATE FILENAME, error return"
		return $ERR_NOARG
	fi

	DTFILE="$*" # date filename

	xmsg "get_datefile_file: DTFILE:$DTFILE"

	echo $DTFILE | awk '{ T=$0; sub(/[\n\r]$/,"",T); F=substr(T,16); print F }'
}
test_get_datefile_file()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1

	DF=`get_datefile_file`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file"

	DF=`get_datefile_file md`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file md"
	DF=`get_datefile_file $DT`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file $DT"
	DF=`get_datefile_file $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_datefile_file $OKFILE"

	DF=`get_datefile_file $DT $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $OKFILE"
	DF=`get_datefile_file $DT $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $NGFILE"
	DF=`get_datefile_file $DT $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $OKFILE2"
	DF=`get_datefile_file $DT $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_datefile_file $DT $NGFILE2"

	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile_file"; VERBOSE=2; test_get_datefile_file; exit 0


do_sync()
{
	# in build

	msg "# synchronizing ..."
        msg "git branch"
        git branch
        msg "git checkout $BRANCH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git checkout $BRANCH
	fi
        msg "git fetch"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git fetch
	fi
        msg "git reset --hard origin/master"
	if [ $NOEXEC -eq $RET_FALSE ]; then
	        git reset --hard origin/master
	fi


	# cd BASEDIR
	msg "# creating FIXSH ..."

	local DT0 DFFIXSH FFIXSH

	DT0=`date '+%m%d'`
	msg "DT0:$DT0"

	# BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}*"
		ls -ltr ${FIXSHNAME}*
	fi
	DFFIXSH=`get_datefile "${FIXSHNAME}*"`
	FFIXSH=`get_datefile_file $DFFIXSH`
	msg "FIXSH:$FFIXSH"

	msg "sh $FFIXSH mk"
	sh $FFIXSH mk
	if [ ! $? -eq $RET_OK ]; then
		die $? "RETCODE:$?: can't make ${FIXBASE}${DT0}.sh, exit"
	fi

	DFFIXSH=`get_datefile "${FIXSHNAME}*"`
	FFIXSH=`get_datefile_file $DFFIXSH`
	msg "$FFIXSH: created"


	# cd BUILDPATH
	msg "cd $BUILDPATH"
	cd $BUILDPATH
}

do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../CMakeLists.txt $DIRNAME|| die 221 "can't copy files"
	chk_and_cp -pr ../src ../include/ggml $DIRNAME || die 222 "can't copy src files"
	chk_and_cp -pr ../examples $DIRNAME || die 223 "can't copy examples files"
	chk_and_cp -pr ../tests $DIRNAME || die 224 "can't copy tests files"
	msg "find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;
	fi

	# $ ls -l ggml/build/0521up/examples/mnist/models/mnist/
	#-rw-r--r-- 1 user user 1591571 May 21 22:45 mnist_model.state_dict
	#-rw-r--r-- 1 user user 7840016 May 21 22:45 t10k-images.idx3-ubyte
	msg "rm -r $DIRNAME/examples/mnist/models"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		rm -r $DIRNAME/examples/mnist/models
	fi
}

do_cmk()
{
	# in build

	msg "# do cmake"
	if [ -f CMakeCache.txt ]; then
		msg "rm CMakeCache.txt"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			rm CMakeCache.txt
		fi
	fi
	msg "cmake .. $CMKOPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cmake .. $CMKOPT || die 231 "cmake failed"
	fi
	msg "cp -p Makefile $DIRNAME/Makefile.build"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p Makefile $DIRNAME/Makefile.build
	fi

	# update targets
	msg "get_targets"
	get_targets
}

do_test()
{
	# in build

	msg "# testing ..."
	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 241 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi
	# update targets
	msg "get_targets"
	get_targets

	msg "make $TESTS"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		make $TESTS || die 242 "make test build failed"
	fi
	msg "env $TESTENV make test"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		env $TESTENV make test || die 243 "make test failed"
	fi
	msg "mv bin/test* $DIRNAME/"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mv bin/test* $DIRNAME || die 244 "can't move tests"
	fi
}

# copy srcfile to dstfile.mmdd and dstfile
cp_script()
{
	local SRC DST DFSRC MDSRC DSTDT

	if [ ! $# -ge 2 ]; then
		emsg "cp_script: RETCODE:$ERR_NOARG: ARG:$*: need SRC DST, error return"
		return $ERR_NOARG
	fi

	SRC="$1"
	DST="$2"
	xmsg "cp_script: SRC:$SRC"
	xmsg "cp_script: DST:$DST"

	if [ ! -f "$SRC" ]; then
		emsg "cp_script: RETCODE:$ERR_NOTEXISTED: $SRC: not found, error return"
		return $ERR_NOTEXISTED
	fi
	if [ "$SRC" = "$DST" ]; then
		emsg "cp_script: RETCODE:$ERR_BADARG: $SRC: $DST: same file, error return"
		return $ERR_BADARG
	fi

	DFSRC=`get_datefile "$SRC"`
	xxmsg "cp_script: DFSRC:$DFSRC"
	MDSRC=`get_datefile_date md $DFSRC`
	xxmsg "cp_script: MDSRC:$MDSRC"
	DSTDT="${DST}.$MDSRC"
	msg "cp -p \"$SRC\" \"$DSTDT\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DSTDT"
	fi
	msg "cp -p \"$SRC\" \"$DST\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DST"
	fi
}
test_cp_script()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	DT=`date '+%m%d'`
	msg "DT:$DT0"
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}* $TMPDIR1"
	ls $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}* $TMPDIR1

	cp_script
	func_test $ERR_NOARG "no arg: cp_script"

	msg "ls -l $OKFILE $NGFILE $OKFILE2 $NGFILE2"
	cp_script $NGFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE"
	cp_script $OKFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE"
	cp_script $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $NGFILE2"
	cp_script $OKFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: cp_script $OKFILE2"

	cp_script $NGFILE $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: cp_script $NGFILE $NGFILE2"
	cp_script $OKFILE $OKFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $OKFILE2"
	cp_script $OKFILE $NGFILE
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE"
	rm $NGFILE
	cp_script $OKFILE $NGFILE2
	RETCODE=$?; ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*; set_ret $RETCODE
	func_test $RET_OK "ok: cp_script $OKFILE $NGFILE2"
	rm $NGFILE2


	msg "rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
	rmdir $TMPDIR1
	msg "ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
}
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_TRUE; test_cp_script; exit 0
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_FALSE; test_cp_script; exit 0

git_script()
{
	msg "# git push scripts ..."

	local DT0 ADDFILES COMMITFILES
	local DFUPDATE DFFIXSH DFMKZIP FUPDATE FFIXSH FMKZIP
	local DFUPDATEG DFFIXSHG DFMKZIPG FUPDATEG FFIXSHG FMKZIPG

	DT0=`date '+%m%d'`
	msg "DT0:$DT0"

	ADDFILES=""
	COMMITFILES=""

	# BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi
	DFUPDATE=`get_datefile "${UPDATENAME}"`
	DFFIXSH=`get_datefile "${FIXSHNAME}*"`
	DFMKZIP=`get_datefile "${MKZIPNAME}"`
	FUPDATE=`get_datefile_file $DFUPDATE`
	FFIXSH=`get_datefile_file $DFFIXSH`
	FMKZIP=`get_datefile_file $DFMKZIP`
	msg "FUPDATE:$FUPDATE"
	msg "FFIXSH:$FFIXSH"
	msg "FMKZIP:$FMKZIP"

	# git SCRIPT branch
	msg "cd $BASEDIR/$TOPDIR"
	cd $BASEDIR/$TOPDIR
	msg "git branch"
	git branch
	msg "git checkout $SCRIPT"
	git checkout $SCRIPT

	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
	fi
	# G git
	DFUPDATEG=`get_datefile "${UPDATENAME}"`
	DFFIXSHG=`get_datefile "${FIXSHNAME}*"`
	DFMKZIPG=`get_datefile "${MKZIPNAME}"`
	FUPDATEG=`get_datefile_file $DFUPDATEG`
	FFIXSHG=`get_datefile_file $DFFIXSHG`
	FMKZIPG=`get_datefile_file $DFMKZIPG`
	msg "FUPDATEG:$FUPDATEG"
	msg "FFIXSHG:$FFIXSHG"
	msg "FMKZIPG:$FMKZIPG"

	msg "diff $FUPDATEG $BASEDIR/$FUPDATE"
	if [ $VERBOSE -ge 1 ]; then
		diff $FUPDATEG $BASEDIR/$FUPDATE
	else
		diff $FUPDATEG $BASEDIR/$FUPDATE > /dev/null
	fi
	if [ $? -eq $RET_OK ]; then
		msg "same: no copy: $BASEDIR/$FUPDATE $FUPDATEG"
	else
		msg "diff: copy: $BASEDIR/$FUPDATE $FUPDATEG"
		cp_script $BASEDIR/$FUPDATE $FUPDATEG
		COMMITFILES="$COMMITFILES $FUPDATEG"
	fi

	if [ $FFIXSH = $FFIXSHG ]; then
		# diff, copy
		msg "diff $FFIXSHG $BASEDIR/$FFIXSH"
		if [ $VERBOSE -ge 1 ]; then
			diff $FFIXSHG $BASEDIR/$FFIXSH
		else
			diff $FFIXSHG $BASEDIR/$FFIXSH > /dev/null
		fi
		if [ $? -eq $RET_OK ]; then
			msg "same: no copy: $BASEDIR/$FFIXSH $FFIXSHG"
		else
			msg "diff: copy: $BASEDIR/$FFIXSH $FFIXSHG"
			cp_script $BASEDIR/$FFIXSH $FFIXSHG
			COMMITFILES="$COMMITFILES $FFIXSHG"
		fi
	else
		# always copy
		msg "always: copy: $BASEDIR/$FFIXSH $FFIXSH"
		msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			cp -p $BASEDIR/$FFIXSH $FFIXSH
			ADDFILES="$ADDFILES $FFIXSH"
			COMMITFILES="$COMMITFILES $FFIXSH"
		fi
	fi

	msg "diff $FMKZIPG $BASEDIR/$FMKZIP"
	if [ $VERBOSE -ge 1 ]; then
		diff $FMKZIPG $BASEDIR/$FMKZIP
	else
		diff $FMKZIPG $BASEDIR/$FMKZIP > /dev/null
	fi
	if [ $? -eq $RET_OK ]; then
		msg "same: no copy: $BASEDIR/$FMKZIP $FMKZIPG"
	else
		msg "diff: copy: $BASEDIR/$FMKZIP $FMKZIPG"
		cp_script $BASEDIR/$FMKZIP $FMKZIPG
		COMMITFILES="$COMMITFILES $FMKZIPG"
	fi

	msg "ADDFILES:$ADDFILES"
	msg "COMMITFILES:$COMMITFILES"
	if [ ! x"$COMMITFILES" = x ]; then
		# avoid error: pathspec 'fix1202.sh' did not match any file(s) known to git.
		msg "git fetch"
		git fetch
		if [ ! x"$ADDFILES" = x ]; then
			msg "git add $ADDFILES"
			git add $ADDFILES
		fi
		msg "git commit -m \"update scripts\" $COMMITFILES"
		git commit -m "update scripts" $COMMITFILES
		msg "git status"
		git status
		msg "git push origin $SCRIPT"
		git push origin $SCRIPT
	fi

	# back
	msg "git checkout $BRANCH"
	git checkout $BRANCH
}
#msg "do_script"; NOEXEC=$RET_TRUE; VERBOSE=2; do_script; exit 0


#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
#./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p \"$PROMPT\""
#./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p "$PROMPT" || die 75 "do gpt-j failed"
#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV"
#./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV || die 89 "do whisper failed"

# do_bin DOBIN MODEL VARPROMPT DOOPT
# do_bin DOBIN MODEL WAVFILE DOOPT
do_bin()
{
	local MODEL VARPROMPT DOOPT DT PROMPTTXT RETCODE

	if [ x"$1" = x ]; then
		msg "${ESCERR}do_bin: need DOBIN, MODEL, VARPROMPT skip${ESCBACK}"
		return $ERR_BADARG
	fi
	DOBIN="$1"
	MODEL="$2"
	VARPROMPT="$3"
	shift 3
	DOOPT="$*"

	RETCODE=$RET_OK

	DT=`date '+%m%d'`

	#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
	#./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
	if [ x"$DOBIN" = x"whisper" ]; then
		WAVFILE=`eval echo '$'${VARPROMPT}`
		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE"
		./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE
		RETCODE=$?
		if [ ! $RETCODE -eq $RET_OK ]; then
			emsg "do $DOBIN failed"
		fi
	else
		if [ ! x"$SEEDOPT" = x ]; then
			SEED=$SEEDOPT
		fi
		PROMPTTXT=`eval echo '$'${VARPROMPT}`

		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p \"$PROMPTTXT\""
		./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p "$PROMPTTXT"
		RETCODE=$?
		if [ ! $RETCODE -eq $RET_OK ]; then
			emsg "do $DOBIN failed"
		fi
	fi

	return $RETCODE
}

do_gpt2()
{
	# in build

	local GPT2BIN DOOPT GPT2MK GPT2BINS i

	GPT2BIN=gpt-2-ctx

	DOOPT="$1"

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 261 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	GPT2MK=$RET_FALSE
	GPT2BINS=
	for i in $GPTS
	do
		GPT2BINS="$GPT2BINS bin/$i"
		if [ ! -f ./$DIRNAME/$i ]; then
			GPT2MK=$RET_TRUE
		fi
	done
	if [ $GPT2MK -eq $RET_TRUE ]; then
		msg "make $GPT2"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make $GPT2 || die 262 "make gpt-2 failed"
		fi
	fi
	if [ $NOCOPY -eq $RET_FALSE -a ! -f ./$DIRNAME/$GPT2BIN ]; then
		msg "mv $GPT2BINS $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			mv $GPT2BINS $DIRNAME || die 263 "can't move gpt-2"
		fi
	fi

	if [ x"$DOOPT" = x"NOEXEC" ]; then
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-q4_0.bin -s $SEED -p \"$PROMPTEX\""
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-q4_1.bin -s $SEED -p \"$PROMPTEX\""
		do_bin $GPT2BIN models/gpt-2-117M/ggml-model-f32.bin PROMPTEX
		do_bin $GPT2BIN models/gpt-2-117M/ggml-model-q4_0.bin PROMPTEX
		do_bin $GPT2BIN models/gpt-2-117M/ggml-model-q4_1.bin PROMPTEX
	else
		msg "skip executing gpt-2"
	fi
}

do_gptj()
{
	# in build

	local DOOPT DOBIN

	DOOPT="$1"
	DOBIN=gpt-j

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 271 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	if [ ! x"$DOOPT" = x"NOMAKE" ]; then
		if [ ! -f ./$DIRNAME/$DOBIN ]; then
			msg "make $DOBIN ${DOBIN}-quantize"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make $DOBIN ${DOBIN}-quantize || die 272 "make $DOBIN failed"
			fi
		fi
	fi
	if [ $NOCOPY -eq $RET_FALSE -a ! -f ./$DIRNAME/$DOBIN ]; then
		msg "mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME || die 273 "can't move $DOBIN"
		fi
	fi

	if [ ! x"$DOOPT" = x"NOEXEC" ]; then
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_1.bin -s $SEED -p \"$PROMPT\""
		do_bin $DOBIN models/gpt-j-6B/ggml-model-f16.bin PROMPT
		do_bin $DOBIN models/gpt-j-6B/ggml-model-q4_0.bin PROMPT
		do_bin $DOBIN models/gpt-j-6B/ggml-model-q4_1.bin PROMPT
	else
		msg "skip executing $DOBIN"
	fi
}

do_whisper()
{
	# in build

	local DOOPT DOBIN

	DOOPT="$1"
	DOBIN=whisper

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 281 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	if [ ! x"$DOOPT" = x"NOMAKE" ]; then
		if [ ! -f ./$DIRNAME/$DOBIN ]; then
			msg "make $DOBIN ${DOBIN}-quantize"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make $DOBIN ${DOBIN}-quantize || die 282 "make $DOBIN failed"
			fi
		fi
	fi
	if [ $NOCOPY -eq $RET_FALSE -a ! -f ./$DIRNAME/$DOBIN ]; then
		msg "mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME || die 283 "can't move $DOBIN"
		fi
	fi

	if [ x"$DOOPT" = x"NOEXEC" ]; then
		#msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-base.bin -f $JFKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-base.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-small.bin -f $JFKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_0.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV"
		do_bin $DOBIN models/whisper/ggml-base.bin JFKWAV "-l en"
		do_bin $DOBIN models/whisper/ggml-base.bin NHKWAV "-l ja"
		do_bin $DOBIN models/whisper/ggml-small.bin JFKWAV "-l en"
		do_bin $DOBIN models/whisper/ggml-small.bin NHKWAV "-l ja"
		do_bin $DOBIN models/whisper/ggml-small-q4_0.bin NHKWAV "-l ja"
		do_bin $DOBIN models/whisper/ggml-small-q4_1.bin NHKWAV "-l ja"
	else
		msg "skip executing $DOBIN"
	fi
}

do_gptneox()
{
	# in build

	local DOOPT DOBIN

	DOOPT="$1"
	DOBIN=gpt-neox

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 291 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	if [ ! x"$DOOPT" = x"NOMAKE" ]; then
		if [ ! -f ./$DIRNAME/$DOBIN ]; then
			msg "make $DOBIN ${DOBIN}-quantize"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make $DOBIN ${DOBIN}-quantize || die 292 "make $DOBIN failed"
			fi
		fi
	fi
	if [ $NOCOPY -eq $RET_FALSE -a ! -f ./$DIRNAME/$DOBIN ]; then
		msg "mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME || die 293 "can't move $DOBIN"
		fi
	fi

	if [ ! x"$DOOPT" = x"NOEXEC" -a -f ./$DIRNAME/$DOBIN ]; then
		#msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-f16.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_0.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_1.bin -s $SEED -p \"$PROMPT\""
		do_bin $DOBIN models/gpt-neox/ggml-3b-f16.bin PROMPT
		do_bin $DOBIN models/gpt-neox/ggml-3b-q4_0.bin PROMPT
		do_bin $DOBIN models/gpt-neox/ggml-3b-q4_1.bin PROMPT

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-q4_0.bin -s $SEED -p "$PROMPTJP""
		do_bin $DOBIN models/cyberagent/ggml-model-calm-large-f32.bin PROMPT
		do_bin $DOBIN models/cyberagent/ggml-model-calm-large-f16.bin PROMPTJP
		do_bin $DOBIN models/cyberagent/ggml-model-calm-large-q4_0.bin PROMPTJP

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-q4_0.bin -s $SEED -p "$PROMPTJP""
		do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-f32.bin PROMPT
		do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-f16.bin PROMPTJP
		do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-q4_0.bin PROMPTJP

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-q4_0.bin -s $SEED -p "$PROMPTJP""
		do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-f32.bin PROMPT
		do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-f16.bin PROMPTJP
		do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-q4_0.bin PROMPTJP
	else
		msg "skip executing $DOBIN"
	fi
}

do_dollyv2()
{
	# in build

	local DOOPT DOBIN

	DOOPT="$1"
	DOBIN=dollyv2

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 301 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	if [ ! x"$DOOPT" = x"NOMAKE" ]; then
		if [ ! -f ./$DIRNAME/$DOBIN ]; then
			msg "make $DOBIN ${DOBIN}-quantize"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make $DOBIN ${DOBIN}-quantize || die 302 "make $DOBIN failed"
			fi
		fi
	fi
	if [ $NOCOPY -eq $RET_FALSE -a ! -f ./$DIRNAME/$DOBIN ]; then
		msg "mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			mv bin/$DOBIN bin/${DOBIN}-quantize $DIRNAME || 303 "can't move $DOBIN"
		fi
	fi

	if [ ! x"$DOOPT" = x"NOEXEC" -a -f ./$DIRNAME/$DOBIN ]; then
		# dolly-v2-3b
		#msg "./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-q5_0.bin -s $SEED -p \"$PROMPTJP\""
		do_bin $DOBIN models/dollyv2/ggml-model-f16.bin PROMPT
		do_bin $DOBIN models/dollyv2/ggml-model-15_0.bin PROMPTJP
		# dolly-v2-12b
		#msg "./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p \"$PROMPT\""
		#./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p "$PROMPT" || die 136 "do dollyv2 failed"
	else
		msg "skip executing $DOBIN"
	fi
}

do_examples()
{
	EXOPT="$1"

	msg "# executing examples ..."
	# make
	if [ ! x"$EXOPT" = xNOMAKE ]; then
		if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
			msg "make clean"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				make clean || die 51 "make clean failed"
				MKCLEAN=$RET_TRUE
			fi
		fi
		msg "make $ALLBINS"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make $ALLBINS || die 52 "make $ALLBINS failed"
		fi
		BINTESTS=""; for i in $ALLBINS ;do BINTESTS="$BINTESTS bin/$i" ;done
		msg "cp -p $BINTESTS $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			cp -p $BINTESTS $DIRNAME || die 53 "can't cp"
			NOCOPY=$RET_TRUE
		fi
	fi

	# exec
	if [ ! x"$EXOPT" = xNOEXEC ]; then
		do_gpt2 $EXOPT
		do_gptj $EXOPT
		do_whisper $EXOPT
		do_gptneox $EXOPT
		do_dollyv2 $EXOPT
	fi
}

###
msg "# start"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ ! -d $TOPDIR ]; then
	die $ERR_NOTOPDIR "# can't find $TOPDIR, exit"
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mkdir -p $BUILDPATH
	fi
	if [ ! -d $BUILDPATH ]; then
		die $ERR_NOBUILDDIR "# can't find $BUILDPATH, exit"
	fi
fi

msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
git branch
msg "git checkout $BRANCH"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git checkout $BRANCH
fi

msg "mkdir $DIRNAME"
if [ $NOEXEC -eq $RET_FALSE ]; then
	mkdir $DIRNAME
fi
if [ ! -e $DIRNAME ]; then
	die $ERR_NOTEXISTED "no directory: $DIRNAME"
fi

case $CMD in
*sy*)	do_sync;;
*sync*)	do_sync;;
*)	msg "no sync";;
esac

case $CMD in
*cp*)	do_cp;;
*copy*)	do_cp;;
*)	msg "no copy";;
esac

case $CMD in
*cmk*)	do_cmk;;
*cmake*)	do_cmk;;
*)	msg "no cmake";;
esac

case $CMD in
*tst*)	do_test;;
*test*)	do_test;;
*)	msg "no make test";;
esac

case $CMD in
*g2*)	do_gpt2;;
*n2*)	do_gpt2 NOG2;;
*)	msg "no make gpt-2";;
esac

case $CMD in
*gj*)	do_gptj;;
*nj*)	do_gptj NOGJ;;
*)	msg "no make gpt-j";;
esac

case $CMD in
*wh*)	do_whisper;;
*nh*)	do_whisper NOWH;;
*)	msg "no make whisper";;
esac

case $CMD in
*gx*)	do_gptneox;;
*nx*)	do_gptneox NOGX;;
*)	msg "no make gpt-neox";;
esac

case $CMD in
*dollyv2*)	do_dollyv2;;
*dl*)	do_dollyv2;;
*nd*)	do_dollyv2 NODL;;
*)	msg "no make dollyv2";;
esac

case $CMD in
*ne*)		do_examples NOEXEC;;
*noex*)		do_examples NOEXEC;;
*exonly*)	do_examples NOMAKE;;
*examples*)	do_examples;;
*ex*)		do_examples;;
*nm*)		do_examples NOEXEC;;
*nomain*)	do_examples NOEXEC;;
*mainonly*)	do_examples NOMAKE;;
*main*)		do_examples;;
*)		msg "no make examples";;
esac

case $CMD in
*script*)	git_script;;
*scr*)		git_script;;
*)		msg "no git push script";;
esac

msg "# done."

