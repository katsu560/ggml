#!/bin/sh

# update katsu560/ggml
# T902 Intel(R) Core(TM) i5-3320M CPU @ 2.60GHz  2C/4T F16C,AVX IvyBridge/3rd Gen.
# AH   Intel(R) Core(TM) i3-10110U CPU @ 2.10GHz  2C/4T F16C,AVX,AVX2,FMA CometLake/10th Gen.

MYNAME=update-katsu560-ggml.sh

TOPDIR=ggml
BUILDPATH="$TOPDIR/build"

OPENBLAS=`grep -sr GGML_OPENBLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*GGML_OPENBLAS.*/GGML_OPENBLAS/'
`
BLAS=`grep -sr GGML_BLAS $TOPDIR/CMakeLists.txt | sed -z -e 's/\n//g' -e 's/.*GGML_BLAS.*/GGML_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
        # CMakeLists.txt w/ GGML_OPENBLAS
        GGML_OPENBLAS="GGML_OPENBLAS"
        BLASVENDOR=""
        echo "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
if [ ! x"$BLAS" = x ]; then
        # CMakeLists.txt w/ GGML_BLAS
        GGML_OPENBLAS="GGML_BLAS"
        BLASVENDOR="-DGGML_BLAS_VENDOR=OpenBLAS"
        echo "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi

#CMKOPT=
CMKOPT="-D$GGML_OPENBLAS=ON $BLASVENDOR"
#CMKOPT="-D$GGML_OPENBLAS=ON $BLASVENDOR -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTNOAVX="-DGGML_AVX=OFF -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF -D$GGML_OPENBLAS=OFF -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTAVX="-DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=ON -D$GGML_OPENBLAS=ON $BLASVENDOR -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPTAVX2="-DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=ON -DGGML_F16C=ON -D$GGML_OPENBLAS=ON $BLASVENDOR -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
#
CMKOPTNONE="-D$GGML_OPENBLAS=ON $BLASVENDOR -DGGML_BUILD_TESTS=ON -DGGML_BUILD_EXAMPLES=ON"
CMKOPT="$CMKOPTNONE"

TESTOPT="GGML_NLOOP=1 GGML_NTHREADS=4"
#TESTS="test-blas0 test-grad0 test-mul-mat0 test-mul-mat1 test-mul-mat2 test-opt test-svd0 test-vec0 test-vec1 test-vec2 test0 test1 test2 test3"
TESTS="test-grad0 test-mul-mat0 test-mul-mat2 test-svd0 test-vec0 test-vec1 test0 test1 test2 test3"
TESTSCPP="test-opt test-quantize-fns test-quantize-perf test-pool test-customop test-conv-transpose test-rel-pos test-xpos"
NOTEST="test-blas0"
for i in $TESTSCPP
do
        if [ -e $TOPDIR/tests/$i.cpp ]; then
                TEST=`basename $i`
                TESTS="$TESTS $TEST"
        fi
        if [ -e $TOPDIR/tests/$i.c ]; then
                TEST=`basename $i`
                TESTS="$TESTS $TEST"
        fi
done

#ALLBINS="gpt-2 gpt-j whisper"
ALLBINS="gpt-2 gpt-2-quantize gpt-j gpt-j-quantize whisper whisper-quantize"
BINSDIR="gpt-neox mpt replit sam"
BINSCPP=""
NOBINS="whisper-cpp"
for i in $BINSDIR
do
        if [ -d $TOPDIR/examples/$i ]; then
                ALLBINS="$ALLBINS $i"
        fi
        if [ -e $TOPDIR/examples/$i/quantize.cpp ]; then
                ALLBINS="$ALLBINS $i-quantize"
        fi
done
for i in $BINSCPP
do
        if [ -e $TOPDIR/examples/$i.cpp ]; then
                BIN=`basename $i`
                ALLBINS="$ALLBINS $BIN"
        fi
done
if [ -d $TOPDIR/examples/mnist ]; then
	ALLBINS="$ALLBINS mnist mnist-cnn mnist-cpu"
fi
if [ -d $TOPDIR/examples/dolly-v2 ]; then
	ALLBINS="$ALLBINS dollyv2 dollyv2-quantize"
fi
if [ -d $TOPDIR/examples/starcoder ]; then
	ALLBINS="$ALLBINS starcoder starcoder-mmap starcoder-quantize"
fi

JFKWAV=jfk.wav
NHKWAV=nhk0521-16000hz1ch-0-10s.wav

PROMPTEX="This is an example"
PROMPT="tell me about creating web site in 5 steps:"
PROMPTJP="京都について教えてください:"
SEED=1685215400

MKCLEAN=0
NODIE=0
NOCLEAN=0
NOCOPY=0

###
msg()
{
	echo "$MYNAME: $*"
}

die()
{
	CODE=$1
	shift
	msg "$*"
	if [ $NODIE = 0 ]; then
		exit $CODE
	fi
}

usage()
{
	echo "usage: $MYNAME [-h][-nd][-nc][-ncp][-noavx|avx|avx2] dirname branch cmd"
	echo "options: (default)"
	echo "-h|--help ... this message"
	echo "-nd|--nodie ... no die"
	echo "-nc|--noclean ... no make clean"
	echo "-ncp|--nocopy ... no copy"
	#echo "-up ... upstream, no mod source, skip test-blas0"
	echo "-noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "dirname ... directory name ex. 0226up"
	echo "branch ... git branch ex. master, gq, devpr"
	echo "cmd ... sycpcmktstex sy/sync,cp/copy,cmk/cmake,tst/test,ex/examples"
	echo "cmd ... sycpcmktstne sy,cp,cmk,tst,ne  ne .. build examples but no exec"
	echo "cmd ... cpcmkg2gjwhtst cp,cmk,g2,gj,wh,gx,dl,tst gpt-2,gpt-j,whisper,gpt-neox,dollyv2"
	echo "cmd ... cpcmkn2njwhtst cp,cmk,n2,nj,nh,nx,nd,tst build gpt-j but no exec, gpt-2, ..."
}

###
if [ x"$1" = x -o $# -lt 3 ]; then
	usage
	exit 1
fi

ALLOPT="$*"
OPTLOOP=1
while [ $OPTLOOP -eq 1 ];
do
	case $1 in
	-h|--help) usage; exit 1;;
	-nd|--nodie) NODIE=1;;
	-nc|--noclean) NOCLEAN=1;;
	-ncp|--nocopy) NOCOPY=1;;
	-up)	ALLBINS="$ALLBINSUP";;
	-noavx)	CMKOPT="$CMKOPTNOAVX";;
	-avx)	CMKOPT="$CMKOPTAVX";;
	-avx2)	CMKOPT="$CMKOPTAVX2";;
	*)	OPTLOOP=0; break;;
	esac
	shift
done

DIRNAME="$1"
BRANCH="$2"
CMD="$3"

###
do_sync()
{
	msg "# synchronizing ..."
        msg "git branch"
        git branch
        msg "git checkout $BRANCH"
        git checkout $BRANCH
        msg "git fetch"
        git fetch
        msg "git reset --hard origin/master"
        git reset --hard origin/master
}

chk_and_cp()
{
        chkfiles="$*"
        if [ x"$chkfiles" = x ]; then
                msg "chk_and_cp: no chkfiles"
                return 1
        fi

        cpopt=$1
        shift
        chkfiles="$*"

        cpfiles=
        for i in $chkfiles
        do
                if [ -f $i ]; then
                        cpfiles="$cpfiles $i"
                elif [ -d $i ]; then
                        cpfiles="$cpfiles $i"
                fi
        done

        msg "cp $cpopt $cpfiles $DIRNAME"
        cp $cpopt $cpfiles $DIRNAME || return 2

        return 0
}

do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../CMakeLists.txt || die 21 "can't copy files"
	chk_and_cp -pr ../src ../include/ggml || die 22 "can't copy src files"
	chk_and_cp -pr ../examples || die 23 "can't copy examples files"
	#msg "cp -pr ../tests $DIRNAME"
	#cp -pr ../tests $DIRNAME || die 24 "can't copy tests files"
	chk_and_cp -pr ../tests || die 24 "can't copy tests files"
	msg "find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;"
	find $DIRNAME -name '*.[0-9][0-9][0-9][0-9]*' -exec rm {} \;

	# $ ls -l ggml/build/0521up/examples/mnist/models/mnist/
	#-rw-r--r-- 1 user user 1591571 May 21 22:45 mnist_model.state_dict
	#-rw-r--r-- 1 user user 7840016 May 21 22:45 t10k-images.idx3-ubyte
	msg "rm -r $DIRNAME/examples/mnist/models"
	rm -r $DIRNAME/examples/mnist/models
}

do_cmk()
{
	# in build

	msg "# do cmake"
	msg "rm CMakeCache.txt"
	rm CMakeCache.txt
	msg "cmake .. $CMKOPT"
	cmake .. $CMKOPT || die 31 "cmake failed"
	msg "cp -p Makefile $DIRNAME/Makefile.build"
	cp -p Makefile $DIRNAME/Makefile.build
}

do_test()
{
	msg "# testing ..."
	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 41 "make clean failed"
	fi
	msg "make $TESTS"
	make $TESTS || die 42 "make test build failed"
	msg "env $TESTOPT make test"
	env $TESTOPT make test || die 43 "make test failed"
	msg "mv bin/test* $DIRNAME/"
	mv bin/test* $DIRNAME || die 44 "can't move tests"
}

do_gpt2()
{
	NOG2="$1"

	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 61 "make clean failed"
	fi

	if [ ! -f ./$DIRNAME/gpt-2 ]; then
		msg "make gpt-2 gpt-2-quantize"
		make gpt-2 gpt-2-quantize || die 62 "make gpt-2 failed"
	fi
	if [ $NOCOPY = 0 -a -f ./$DIRNAME/gpt-2 ]; then
		msg "mv bin/gpt-2 bin/gpt-2-quantize $DIRNAME/"
		mv bin/gpt-2 bin/gpt-2-quantize $DIRNAME || die 63 "can't move gpt-2"
	fi

	if [ x"$NOG2" = x ]; then
		msg "./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
		./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
		msg "./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-q4_0.bin -s $SEED -p \"$PROMPTEX\""
		./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-q4_0.bin -s $SEED -p "$PROMPTEX" || die 65 "do gpt-2 failed"
		msg "./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-q4_1.bin -s $SEED -p \"$PROMPTEX\""
		./$DIRNAME/gpt-2 -m models/gpt-2-117M/ggml-model-q4_1.bin -s $SEED -p "$PROMPTEX" || die 66 "do gpt-2 failed"
	else
		msg "skip executing gpt-2"
	fi
}

do_gptj()
{
	NOGJ="$1"

	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 71 "make clean failed"
	fi

	if [ ! -f ./$DIRNAME/gpt-j ]; then
		msg "make gpt-j gpt-j-quantize"
		make gpt-j gpt-j-quantize || die 72 "make gpt-j failed"
	fi
	if [ $NOCOPY = 0 -a -f ./$DIRNAME/gpt-j ]; then
		msg "mv bin/gpt-j bin/gpt-j-quantize $DIRNAME/"
		mv bin/gpt-j bin/gpt-j-quantize $DIRNAME || die 73 "can't move gpt-j"
	fi

	if [ x"$NOGJ" = x ]; then
		msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-f16.bin -s $SEED -p "$PROMPT" || die 74 "do gpt-j failed"
		msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p "$PROMPT" || die 75 "do gpt-j failed"
		msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_1.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_1.bin -s $SEED -p "$PROMPT" || die 76 "do gpt-j failed"
	else
		msg "skip executing gpt-j"
	fi
}

do_whisper()
{
	NOWH="$1"

	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 81 "make clean failed"
	fi

	if [ ! -f ./$DIRNAME/whisper ]; then
		msg "make whisper whisper-quantize"
		make whisper whisper-quantize || die 82 "make whisper failed"
	fi
	if [ $NOCOPY = 0 -a -f ./$DIRNAME/whisper ]; then
		msg "mv bin/whisper bin/whisper-quantize $DIRNAME/"
		mv bin/whisper $DIRNAME || die 83 "can't move whisper"
	fi

	if [ x"$NOWH" = x ]; then
		msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-base.bin -f $JFKWAV"
		./$DIRNAME/whisper -l en -m models/whisper/ggml-base.bin -f $JFKWAV || die 84 "do whisper failed"
		msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-base.bin -f $NHKWAV"
		./$DIRNAME/whisper -l ja -m models/whisper/ggml-base.bin -f $NHKWAV || die 85 "do whisper failed"
		msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-small.bin -f $JFKWAV"
		./$DIRNAME/whisper -l en -m models/whisper/ggml-small.bin -f $JFKWAV || die 86 "do whisper failed"
		msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small.bin -f $NHKWAV"
		./$DIRNAME/whisper -l ja -m models/whisper/ggml-small.bin -f $NHKWAV || die 87 "do whisper failed"
		msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_0.bin -f $NHKWAV"
		./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_0.bin -f $NHKWAV || die 88 "do whisper failed"
		msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV"
		./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV || die 89 "do whisper failed"
	else
		msg "skip executing whisper"
	fi
}

do_gptneox()
{
	NOGX="$1"

	if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
		MKCLEAN=1
		msg "make clean"
		make clean || die 91 "make clean failed"
	fi

	if [ ! -f ./$DIRNAME/gpt-neox ]; then
		msg "make gpt-neox gpt-neox-quantize"
		make gpt-neox gpt-neox-quantize || die 92 "make gpt-neox failed"
	fi
	if [ $NOCOPY = 0 -a -f ./$DIRNAME/gpt-neox ]; then
		msg "mv bin/gpt-neox bin/gpt-neox-quantize $DIRNAME/"
		mv bin/gpt-neox bin/gpt-neox-quantize $DIRNAME || die 93 "can't move gpt-neox"
	fi

	if [ x"$NOGX" = x -a ./$DIRNAME/gpt-neox ]; then
		msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-f16.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-f16.bin -s $SEED -p "$PROMPT" || die 94 "do gpt-neox failed"
		msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_0.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_0.bin -s $SEED -p "$PROMPT" || die 95 "do gpt-neox failed"
		msg "./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_1.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/gpt-neox -m models/gpt-neox/ggml-3b-q4_1.bin -s $SEED -p "$PROMPT" || die 96 "do gpt-neox failed"

		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f32.bin -s $SEED -p "$PROMPT""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f32.bin -s $SEED -p "$PROMPT" || die 101 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p "$PROMPTJP" || die 102 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-q4_0.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-q4_0.bin -s $SEED -p "$PROMPTJP" || die 103 "do gpt-neox calm failed"

		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f32.bin -s $SEED -p "$PROMPT""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f32.bin -s $SEED -p "$PROMPT" || die 111 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f16.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f16.bin -s $SEED -p "$PROMPTJP" || die 112 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-q4_0.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-q4_0.bin -s $SEED -p "$PROMPTJP" || die 113 "do gpt-neox calm failed"

		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f32.bin -s $SEED -p "$PROMPT""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f32.bin -s $SEED -p "$PROMPT" || die 121 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f16.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f16.bin -s $SEED -p "$PROMPTJP" || die 122 "do gpt-neox calm failed"
		msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-q4_0.bin -s $SEED -p "$PROMPTJP""
		./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-q4_0.bin -s $SEED -p "$PROMPTJP" || die 123 "do gpt-neox calm failed"
	else
		msg "skip executing gpt-neox"
	fi
}

do_dollyv2()
{
	if [ -f ./$DIRNAME/dollyv2 ]; then
		# dolly-v2-3b
		msg "./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
		./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-f16.bin -s $SEED -p "$PROMPT" || die 134 "do dollyv2 failed"
		msg "./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-q5_0.bin -s $SEED -p \"$PROMPTJP\""
		./$DIRNAME/dollyv2 -m models/dollyv2/ggml-model-q5_0.bin -s $SEED -p "$PROMPTJP" || die 135 "do dollyv2 failed"
		# dolly-v2-12b
		#msg "./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p \"$PROMPT\""
		#./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p "$PROMPT" || die 136 "do dollyv2 failed"
	fi
}

do_examples()
{
	EXOPT="$1"

	msg "# executing examples ..."
	# make
	if [ ! x"$EXOPT" = xNOMAKE ]; then
		if [ $MKCLEAN = 0 -a $NOCLEAN = 0 ]; then
			MKCLEAN=1
			msg "make clean"
			make clean || die 51 "make clean failed"
		fi
		msg "make $ALLBINS"
		make $ALLBINS || die 52 "make $ALLBINS failed"
		BINTESTS=""; for i in $ALLBINS ;do BINTESTS="$BINTESTS bin/$i" ;done
		msg "cp -p $BINTESTS $DIRNAME/"
		cp -p $BINTESTS $DIRNAME || die 53 "can't cp"
		NOCOPY = 1
	fi

	# exec
	if [ ! x"$EXOPT" = xNOEXEC ]; then
		do_gpt2
		do_gptj
		do_whisper
		do_gptneox
		do_dollyv2
	fi
}

###
msg "# start"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
sudo ntpdate ntp.nict.jp

# check
if [ ! -d $TOPDIR ]; then
	msg "# can't find $TOPDIR, exit"
	exit 2
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	mkdir -p $BUILDPATH
	if [ ! -d $BUILDPATH ]; then
		msg "# can't find $BUILDPATH, exit"
		exit 3
	fi
fi


msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
git branch
msg "git checkout $BRANCH"
git checkout $BRANCH

msg "mkdir $DIRNAME"
mkdir $DIRNAME
if [ ! -e $DIRNAME ]; then
	msg "no directory: $DIRNAME"
	exit 11
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
*mainonly*)	do_examples NOMAKE;;
*main*)		do_examples;;
*)		msg "no make examples";;
esac

msg "# done."

