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
ERR_BADSETTINGS=18	# bad settings
ERR_BADENVIRONMENT=19	# bad environment
ERR_BADENV=19		# bad environment, short name

# set unique return code from 100
ERR_NOTOPDIR=100        # no topdir
ERR_NOBUILDDIR=101      # no build dir
ERR_NOUSB=102		# no USB found


### flags
VERBOSE=0               # -v --verbose flag, -v -v means more verbose
NOEXEC=$RET_FALSE       # -n --noexec flag
FORCE=$RET_FALSE        # -f --force flag
NODIE=$RET_FALSE        # -nd --nodie
NOCOPY=$RET_FALSE       # -ncp --nocopy
NOTHING=

LEVELMIN=1
LEVELSTD=3
LEVELMAX=5
DOLEVEL=$LEVELSTD

### date time
DTTMSHSTART=


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
ESCBGBLACK="${ESC}[40m"
ESCBGRED="${ESC}[41m"
ESCBGGREEN="${ESC}[42m"
ESCBGYELLOW="${ESC}[43m"
ESCBGBLUE="${ESC}[44m"
ESCBGMAGENTA="${ESC}[45m"
ESCBGCYAN="${ESC}[46m"
ESCBGWHITE="${ESC}[47m"
ESCBGDEFAULT="${ESC}[49m"
ESCBACK="${ESC}[m"

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

# func:msg ver:2023.12.23
# message to stdout
# msg "messages"
msg()
{
	echo "$MYNAME: $*"
}

# func:die ver:2023.12.31
# die with RETCODE and error message
# die RETCODE "messages"
die()
{
	local RETCODE

	RETCODE=$1
	shift
	xxmsg "die: RETCODE:$RETCODE msg:$*"

	emsg "$*"
	if [ $NODIE -eq $RET_TRUE ]; then
		xmsg "die: nodie"
		return
	fi
	exit $RETCODE
}

# func:nothing ver:2023.12.23
# do nothing function
# nothing
nothing()
{
	NOTHING=
}

FUNCTEST_OK=0
FUNCTEST_NG=0
# func:func_test_reset ver:2023.12.30
# reset FUNCTEST_OK, FUNCTEST_NG
# func_test_reset
func_test_reset()
{
	FUNCTEST_OK=0
	FUNCTEST_NG=0
	xmsg "func_test_reset: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG"
}

# func:func_test_show ver:2023.12.30
# show FUNCTEST_OK, FUNCTEST_NG
# func_test_reset
func_test_show()
{
	if [ $FUNCTEST_NG -eq 0 ]; then
		msg "${ESCOK}func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG${ESCBACK}"
	else
		msg "${ESCERR}func_test_show: FUNCTEST_OK:$FUNCTEST_OK FUNCTEST_NG:$FUNCTEST_NG${ESCBACK}"
	fi
}

# func:func_test ver:2023.12.30
# check return code of func test with OKCODE and output message for test code
# func_test OKCODE "messages"
func_test()
{
	RETCODE=$?

	OKCODE=$1
	shift
	TESTMSG="$*"

	if [ $RETCODE -eq $OKCODE ]; then
		FUNCTEST_OK=`expr $FUNCTEST_OK + 1`
		msg "${ESCOK}test:OK${ESCBACK}: ret:$RETCODE expected:$OKCODE $TESTMSG"
	else
		FUNCTEST_NG=`expr $FUNCTEST_NG + 1`
		msg "${ESCERR}${ESCBOLD}test:NG${ESCBOLDOFF}${ESCBACK}: ret:$RETCODE expected:$OKCODE ${ESCRED}$TESTMSG${ESCBACK}"
	fi
	msg "----"
}

# func:set_ret ver:2023.12.23
# set $? as return code for test code
# set_ret RETCODE
set_ret()
{
	return $1
}

# func:chk_level ver: 2024.01.03
# check given LEVEL less or equal than DOLEVEL, then do ARGS
# chk_level LEVEL ARGS ...
chk_level()
{
	xxmsg "chk_level: DOLEVEL:$DOLEVEL LEVEL:$1 ARGS:$*"

	local LEVEL RETCODE CHK

	RETCODE=$RET_OK

	# check DOLEVEL
	if [ x"$DOLEVEL" = x ]; then
		emsg "chk_level: need set DOLEVEL, skip"
		return $ERR_BADSETTINGS
	fi
	# check args
	if [ x"$1" = x ]; then
		emsg "chk_level: need LEVEL, skip"
		return $ERR_NOARG
	fi
	LEVEL="$1"
	CHK=`echo $LEVEL | awk '!/['$LEVELMIN'-'$LEVELMAX']/ { print "BADVALUE"; exit } { print $0 }'`
	if [ $CHK = "BADVALUE" ]; then
		emsg "chk_level: LEVEL:$LEVEL bad value, skip"
		return $ERR_BADARG
	fi
	if [ $LEVEL -lt $LEVELMIN -o $LEVELMAX -lt $LEVEL ]; then
		emsg "chk_level: LEVEL:$LEVEL bad value, skip"
		return $ERR_BADARG
	fi
	shift
	if [ ! $# -gt 0 ]; then
		emsg "chk_level: need ARGS, skip"
		return $ERR_NOARG
	fi

	xmsg "chk_level: LEVEL:$DOLEVEL >= $LEVEL do $*"
	if [ $DOLEVEL -ge $LEVEL ]; then
		xmsg "chk_level: do $*"
		eval $*
		RETCODE=$?
	else
		xmsg "${ESCWARN}chk_level: skip $*${ESCBACK}"
		RETCODE=$RET_OK
	fi

	xxmsg "chk_level: RETCODE:$RETCODE"
	return $RETCODE
}
test_chk_level_func()
{
	msg "${ESCOK}test_chk_level_func: $*${ESCBACK}"
	return $RET_OK
}
test_chk_level()
{
	local DOLEVELBK LEVELNONUM LEVELZERO LEVELBAD

	# set test env
	DOLEVELBK=$DOLEVEL
	LEVELNONUM="NONUM"
	LEVELZERO=`expr $LEVELMIN - 1`
	LEVELBAD=`expr $LEVELMAX + 1`
	func_test_reset

	# test code
	DOLEVEL=
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_BADSETTINGS "bad settings: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADSETTINGS "bad settings: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELMIN
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELSTD
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	DOLEVEL=$LEVELMAX
	msg "----"
	msg "test_chk_level: DOLEVEL:$DOLEVEL"
	chk_level
	func_test $ERR_NOARG "no arg: chk_level"

	chk_level $LEVELMIN
	func_test $ERR_NOARG "no arg: chk_level $LEVELMIN"
	chk_level $LEVELMIN test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func"
	chk_level $LEVELMIN test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1"
	chk_level $LEVELMIN test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMIN test_chk_level_func arg1 arg2"
	chk_level $LEVELSTD
	func_test $ERR_NOARG "no arg: chk_level $LEVELSTD"
	chk_level $LEVELSTD test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func"
	chk_level $LEVELSTD test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1"
	chk_level $LEVELSTD test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELSTD test_chk_level_func arg1 arg2"
	chk_level $LEVELMAX
	func_test $ERR_NOARG "no arg: chk_level $LEVELMAX"
	chk_level $LEVELMAX test_chk_level_func
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func"
	chk_level $LEVELMAX test_chk_level_func arg1
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1"
	chk_level $LEVELMAX test_chk_level_func arg1 arg2
	func_test $RET_OK "ok: chk_level $LEVELMAX test_chk_level_func arg1 arg2"
	chk_level $LEVELNONUM
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM"
	chk_level $LEVELNONUM test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELNONUM test_chk_level_func"
	chk_level $LEVELNONUM test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1"
	chk_level $LEVELNONUM test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: $LEVELNONUM test_chk_level_func arg1 arg2"
	chk_level $LEVELZERO
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO"
	chk_level $LEVELZERO test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func"
	chk_level $LEVELZERO test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1"
	chk_level $LEVELZERO test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELZERO test_chk_level_func arg1 arg2"
	chk_level $LEVELBAD
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD"
	chk_level $LEVELBAD test_chk_level_func
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func"
	chk_level $LEVELBAD test_chk_level_func arg1
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1"
	chk_level $LEVELBAD test_chk_level_func arg1 arg2
	func_test $ERR_BADARG "bad arg: chk_level $LEVELBAD test_chk_level_func arg1 arg2"

	# reset test env
	func_test_show
	DOLEVEL=$DOLEVELBK
}
#msg "test_chk_level"; VERBOSE=2; test_chk_level; exit 0

# func:get_datetime ver:2023.12.31
# get date time and store to VARDTTM
# get_date VARDTTM
get_datetime()
{
	xxmsg "get_datetime: ARGS:$*"

	local RETCODE VARDTTM DTTM VALDTTM

	RETCODE=$RET_OK

	# check VARDTTM
	if [ x"$1" = x ]; then
		emsg "get_datetime: need VARDTTM, skip"
		return $ERR_NOARG
	fi
	VARDTTM="$1"
	xxmsg "get_datetime: VARDTTM:$VARDTTM"

	DTTM=`date '+%Y%m%d-%H%M%S'`
	eval $VARDTTM="$DTTM"
	VALDTTM=`eval echo '$'${VARDTTM}`
	xxmsg "get_datetime: DTTM:$DTTM $VARDTTM:$VALDTTM"

	return $RETCODE
}
test_get_datetime()
{
	local DTTMTEST

	# set test env
	DTTMTEST=
	msg "DTTMTEST:$DTTMTEST"
	date '+%Y%m%d-%H%M%S'
	func_test_reset

	# test code
	get_datetime
	func_test $ERR_NOARG "no arg: get_datetime"
	msg "DTTMTEST:$DTTMTEST"
	get_datetime DTTMTEST
	func_test $RET_OK "ok: get_datetime DTTMTEST"
	msg "DTTMTEST:$DTTMTEST"

	# reset test env
	func_test_show
	DTTMTEST=
}
#msg "test get_datetime"; VERBOSE=2; test_get_datetime; exit 0
get_datetime DTTMSHSTART

# func:diff_datetime ver:2023.12.31
# get date time difference in second
# get_date DTTMSTART DTTMEND
diff_datetime()
{
	xxmsg "diff_datetime: ARGS:$*"

	local RETCODE DTTMS DTTME DIFF

	RETCODE=$RET_OK

	# check
	if [ $# -lt 2 ]; then
		emsg "diff_datetime: need DTTMSTART DTTMEND, skip"
		return $ERR_NOARG
	fi
	DTTMS="$1"
	DTTME="$2"

	DIFF=`echo -e "$DTTMS\n$DTTME" | awk '
	{ T=$0; NDT=patsplit(T, DT, /([0-9][0-9])/); 
	  I=I+1; SDT[I]=sprintf("%02d%02d %2d %2d %2d %2d %2d\n",DT[1],DT[2],DT[3],DT[4],DT[5],DT[6],DT[7]); S[I]=mktime(SDT[I]) }
	END { DIFF=S[2]-S[1]; printf("%d",DIFF)}'`
	echo $DIFF

	return $RETCODE
}
test_diff_datetime()
{
	local DTTMS DTTME DTTME2 DTTMU DIFF DIFFOK

	# set test env
	DTTMS=20231229-064933
	DTTME=20231229-085939
	DTTME2=20231230-085939
	DTTMU=
	DIFF=
	DIFFOK=7806
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"
	func_test_reset

	# test code
	DIFF=`diff_datetime`
	func_test $ERR_NOARG "no arg: diff_datetime"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTME`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTME2`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME2"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTMS`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTME $DTTMS`
	func_test $RET_OK "ok: diff_datetime $DTTME $DTTMS"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTMU`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMS $DTTMU"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMU $DTTME`
	func_test $ERR_NOARG "no arg: diff_datetime $DTTMU $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DTTMU:$DTTMU DIFF:$DIFF"
	DIFF=`diff_datetime $DTTMS $DTTME`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"

	DIFF=`diff_datetime $DTTMS $DTTME ABC`
	func_test $RET_OK "ok: diff_datetime $DTTMS $DTTME"
	msg "DTTMS:$DTTMS DTTME:$DTTME DIFF:$DIFF"

	# reset test env
	func_test_show
	DTTMS=
	DTTME=
	DTTMU=
	DIFF=
}
#msg "test diff_datetime"; VERBOSE=2; test_diff_datetime; exit 0
# func:chk_and_cp ver:2023.12.30
# do cp with cp option and check source file(s) and dir(s) to file or dir
# chk_and_cp CPOPT SRCFILE SRCDIR ... DSTPATH
chk_and_cp()
{
	local chkfiles cpopt narg argfiles dstpath ncp cpfiles i

	#xmsg "----"
	#xmsg "chk_and_cp: VERBOSE:$VERBOSE NOEXEC:$NOEXEC NOCOPY:$NOCOPY"
	#xmsg "chk_and_cp: $*"
	#xmsg "chk_and_cp: nargs:$# args:$*"
	if [ $# -eq 0 ]; then
		emsg "chk_and_cp: ARG:$*: no cpopt, chkfiles"
		return $ERR_NOARG
	fi

	# get cp opt
	cpopt=$1
	shift
	#xmsg "chk_and_cp: narg:$# args:$*"

	if [ $# -le 1 ]; then
		emsg "chk_and_cp: CPOPT:$cpopt ARG:$*: bad arg, not enough"
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

	xmsg "chk_and_cp: cpopt:$cpopt ncp:$ncp cpfiles:$cpfiles dstpath:$dstpath"
	if [ x"$cpfiles" = x ]; then
		emsg "chk_and_cp: bad arg, no cpfiles"
		return $ERR_BADARG
	fi

	if [ x"$dstpath" = x ]; then
		emsg "chk_and_cp: bad arg, no dstpath$"
		return $ERR_BADARG
	fi

	if [ $ncp -eq 1 ]; then
		emsg "chk_and_cp: bad arg, only 1 parameter:$cpfiles $dstpath"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_BADARG
		else
			msg "${ESC_WARN}NOEXEC, return $RET_OK${ESC_BACK}"
			return $RET_OK
		fi
	elif [ $ncp -eq 2 ]; then
		if [ -f $cpfiles -a ! -e $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -f $dstpath -a $cpfiles = $dstpath ]; then
			emsg "chk_and_cp: bad arg, same file"
			return $ERR_BADARG
		elif [ -d $cpfiles -a -f $dstpath ]; then
			emsg "chk_and_cp: bad arg, dir to file"
			return $ERR_BADARG
		elif [ -f $cpfiles -a -f $dstpath ]; then
			nothing
		elif [ -f $cpfiles -a -d $dstpath ]; then
			nothing
		fi
	elif [ ! -e $dstpath ]; then
		emsg "chk_and_cp: dstpath:$dstpath: not existed"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			return $ERR_NOTEXISTED
		else
			msg "${ESC_WARN}NOEXEC, return $RET_OK${ESC_BACK}"
			return $RET_OK
		fi
	elif [ ! -d $dstpath ]; then
		emsg "chk_and_cp: not dir"
		return $ERR_NOTDIR
	fi

	if [ $NOEXEC -eq $RET_FALSE -a $NOCOPY -eq $RET_FALSE ]; then
		msg "cp $cpopt $cpfiles $dstpath"
		cp $cpopt $cpfiles $dstpath || return $?
	else
		msg "${ESCWARN}noexec: cp $cpopt $cpfiles $dstpath${ESCBACK}"
	fi

	return $RET_OK
}

# chk_and_cp test code
test_chk_and_cp()
{
	# test files and dir, test-no.$$, testdir-no.$$: not existed
	touch test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$
	rm test-no.$$
	mkdir testdir.$$
	rmdir testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: create test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
	func_test_reset

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

	# reset test env
	func_test_show
	rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$
	rm -rf testdir.$$ testdir-no.$$
	ls -ld test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$
	msg "test_chk_and_cp: rm test.$$ test-1.$$ test-2.$$ test-3.$$ test-4.$$ test-5.$$ test-6.$$ test-7.$$ test-8.$$ test-9.$$ test-10.$$ test-no.$$ testdir.$$ testdir-no.$$"
}
#msg "test_chk_and_cp"; VERBOSE=2; test_chk_and_cp; exit 0

# func:get_latestdatefile ver: 2023.12.30
# yyyymmddHHMMSS filename
# get latest date and filename given FILENAME
# get_datefile FILENAME
get_latestdatefile()
{
	local FILE FILES i

	if [ ! $# -ge 1 ]; then
		emsg "get_latestdatefile: RETCODE:$ERR_NOARG: ARG:$*: need FILENAME, error return"
		return $ERR_NOARG
	fi

	FILE="$1"

	xmsg "get_latestdatefile: FILE:$FILE ARG:$*"

	FILES=`eval echo $FILE`
	xmsg "get_latestdatefile: FILES:$FILES"
	for i in $FILES
	do
		if [ ! -e $i ]; then
			emsg "get_latestdatefile: RETCODE:$ERR_NOTEXISTED: $FILE: not found, error return"
			return $ERR_NOTEXISTED
		fi
	done

	ls -ltr --time-style=+%Y%m%d%H%M%S $FILES | awk '
	BEGIN { XDT="0"; XNM="" }
	#{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; printf("%s %s D:%s %s\n",XDT,XNM,DT,NM) >> /dev/stderr }
	{ DT=$6; T=$0; sub(/[\n\r]$/,"",T); I=index(T,DT); I=I+length(DT)+1; NM=substr(T,I); if (DT > XDT) { XDT=DT; XNM=NM }; }
	END { printf("%s %s\n",XDT,XNM) }
	'

	return $?
}
test_get_latestdatefile()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	# set test env
	DT=20231203145627
	OKFILE=test.$$
	OKFILE1=test.$$.1
	NGFILE=test-no.$$
	touch $OKFILE $OKFILE1
	rm $NGFILE
	TMPDIR1=tmpdir.$$
	mkdir $TMPDIR1
	OKFILE2=$TMPDIR1/test2.$$
	NGFILE2=$TMPDIR1/test-no2.$$
	touch $OKFILE2
	rm $NGFILE2
	msg "ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
	func_test_reset

	# test code
	DF=`get_latestdatefile`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOARG "no arg: get_latestdatefile"

	DF=`get_latestdatefile $NGFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_latestdatefile $NGFILE"
	DF=`get_latestdatefile $OKFILE`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE"
	DF=`get_latestdatefile $OKFILE1`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE1"
	DF=`get_latestdatefile $OKFILE*`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE*"
	DF=`get_latestdatefile "$OKFILE*"`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile \"$OKFILE*\""
	DF=`get_latestdatefile $NGFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $ERR_NOTEXISTED "not existed: get_latestdatefile $NGFILE2"
	DF=`get_latestdatefile $OKFILE2`
	RETCODE=$?; msg "DF:$DF"; set_ret $RETCODE
	func_test $RET_OK "ok: get_latestdatefile $OKFILE2"

	# reset test env
	func_test_show
	rm $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $OKFILE1 $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_latestdatefile"; VERBOSE=2; test_get_latestdatefile; exit 0

# func:get_datefile_date ver: 2023.12.30
# Ymd|ymd|md|full yyyymmddHHMMSS filename
# get date given YMDoption(Ymd,ymd,md,full) DATE FILENAME
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

	# set test env
	DT=20231203145627
	OKFILE=test.$$
	NGFILE=test-no.$$
	touch $OKFILE
	rm $NGFILE
	ls $OKFILE $NGFILE
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	rm $OKFILE $NGFILE
}
#msg "test_get_datefile_date"; VERBOSE=2; test_get_datefile_date; exit 0

# func:get_datefile_file ver: 2023.12.30
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

	# set test env
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
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	rm $OKFILE $NGFILE $OKFILE2 $NGFILE2
	rmdir $TMPDIR1
	msg "ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1"
	ls $OKFILE $NGFILE $OKFILE2 $NGFILE2 $TMPDIR1
}
#msg "test_get_datefile_file"; VERBOSE=2; test_get_datefile_file; exit 0

# func:find_latest ver: 2023.12.31
# find latest created/modified files from DTTMSTART, use DTTMSHSTART if no VARDTTMSTART
# find_latest [VARDTTMSTART]
find_latest()
{
	local VARDTTMSTART DTTMNOW DTTMSTART DTTMSEC DTTMMIN

	if [ ! x"$1" = x ]; then
		VARDTTMSTART=$1
	else
		VARDTTMSTART=DTTMSHSTART
	fi

	get_datetime DTTMNOW
	xmsg "find_latest: DTTMNOW:$DTTMNOW"

	xmsg "find_latest: VARDTTMSTART:$VARDTTMSTART"
	DTTMSTART=`eval echo '$'${VARDTTMSTART}`
	xmsg "find_latest: DTTMSTART:$DTTMSTART"

	DTTMSEC=`diff_datetime $DTTMSTART $DTTMNOW`
	DTTMMIN=`expr $DTTMSEC + 59`
	DTTMMIN=`expr $DTTMMIN / 60`
	xmsg "find_latest: DTTMSEC:$DTTMSEC DTTMMIN:$DTTMMIN"

	xmsg "find . -maxdepth 1 -type f -cmin -$DTTMMIN -mmin -$DTTMMIN -exec ls -l '{}' \;"
	find . -maxdepth 1 -type f -cmin -$DTTMMIN -mmin -$DTTMMIN -exec ls -l '{}' \;
}
test_find_latest()
{
	local DTTMSTART1 DTTMSTART2

	# set env
	sleep 1
	get_datetime DTTMSTART1
	touch tmp1.$$ tmp2.$$
	msg "wait 60 sec ..."
	sleep 60
	touch tmp3.$$ tmp4.$$
	get_datetime DTTMSTART2
	msg "DTTMSHSTART:$DTTMSHSTART DTTMSTART1:$DTTMSTART1 DTTMSTART2:$DTTMSTART2"
	ls -l tmp1.$$ tmp2.$$ tmp3.$$ tmp4.$$
	func_test_reset

	# test code
	find_latest
	func_test $RET_OK "ok: find_latest tmp1-4"
	find_latest DTTMSHSTART
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSHSTART tmp1-4"
	find_latest DTTMSTART1
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSTART1 tmp1-4"
	find_latest DTTMSTART2
	func_test $RET_OK "ok: find_latest DTTMSHSTART:$DTTMSTART2 tmp3-4"

	# reset env
	func_test_show
	DTTMSTART1=
	DTTMSTART2=
	rm tmp1.$$ tmp2.$$ tmp3.$$ tmp4.$$
}
#msg "test_find_latest"; VERBOSE=2; test_find_latest; exit 0


###
TOPDIR=ggml
BASEDIR=~/github/$TOPDIR
BUILDPATH="$BASEDIR/$TOPDIR/build"
# script
SCRIPT=script
FIXBASE="fix"
SCRIPTNAME=ggml
UPDATENAME=update-katsu560-${SCRIPTNAME}.sh
FIXSHNAME=${FIXBASE}[0-9][0-9][01][0-9][0-3][0-9].sh
MKZIPNAME=mkzip-${SCRIPTNAME}.sh

# cmake
# check OpenBLAS
BLASCMKLIST="$TOPDIR/CMakeLists.txt"
if [ ! -f $BLASCMKLIST ]; then
	die $ERR_NOTEXISTED "not existed: BLASCMKLIST:$BLASCMKLIST, exit"
fi
OPENBLAS=`grep -sr GGML_OPENBLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*GGML_OPENBLAS.*/GGML_OPENBLAS/'`
BLAS=`grep -sr GGML_BLAS $BLASCMKLIST | sed -z -e 's/\n//g' -e 's/.*GGML_BLAS.*/GGML_BLAS/'`
if [ ! x"$OPENBLAS" = x ]; then
        # CMakeLists.txt w/ GGML_OPENBLAS
        GGML_OPENBLAS="-DGGML_OPENBLAS=ON"
        BLASVENDOR=""
        msg "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
else
	GGML_OPENBLAS=
        BLASVENDOR=
fi
if [ ! x"$BLAS" = x ]; then
        # CMakeLists.txt w/ GGML_BLAS
        GGML_OPENBLAS="-DGGML_BLAS=ON"
        BLASVENDOR="-DGGML_BLAS_VENDOR=OpenBLAS"
        msg "# use GGML_OPENBLAS=$GGML_OPENBLAS BLASVENDOR=$BLASVENDOR"
fi
CMKOPTBLAS="$GGML_OPENBLAS $BLASVENDOR"

CMKOPTTEST="-DGGML_BUILD_TESTS=ON"
CMKOPTEX="-DGGML_BUILD_EXAMPLES=ON"
CMKCOMMON="$CMKOPTTEST $CMKOPTEX"
CMKOPTNOAVX="-DGGML_AVX=OFF -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=OFF $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX="-DGGML_AVX=ON -DGGML_AVX2=OFF -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=OFF -DGGML_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTAVX2="-DGGML_AVX=ON -DGGML_AVX2=ON -DGGML_AVX512=OFF -DGGML_AVX512_VBMI=OFF -DGGML_AVX512_VNNI=OFF -DGGML_FMA=ON -DGGML_F16C=ON $CMKOPTBLAS $CMKCOMMON"
CMKOPTNONE="$CMKOPTBLAS $CMKCOMMON"
CMKOPT="$CMKOPTNONE"
CMKOPT2=""
#msg "CMKOPTBLAS:$CMKOPTBLAS CMKOPT:$CMKOPT CMKOPT2:$CMKOPT2"; exit 0

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
NOTGTSTEST="all clean depend edit_cache install install/local install/strip list_install_components rebuild_cache test"
NOTEST="test-blas0"
NOTGTS="whisper-cpp"
NOTGTSTEST="$NOTGTSTEST common common-ggml ggml $NOTGTS"
TARGETS=
TESTS=
GPT2=

get_targets()
{
	local XTARGETS i

	if [ ! -e $BUILDPATH/Makefile ]; then
		msg "no $BUILDPATH/Makefile"
		return $ERR_NOTEXISTED
	fi

	XTARGETS=`awk -v NOTGTSTEST="$NOTGTSTEST" '
	BEGIN { ST=0; split(NOTGTSTEST,NOTGT); }
	function is_notgt(tgt) {
		for(i in NOTGT) { if (NOTGT[i]==tgt) return 1; continue }
		return 0;
	}
	ST==0 && /^help:/ { ST=1 }
	ST==1 && /^.PHONY : help/ { ST=2 }
	ST==1 && /echo .\.\.\./ { T=$0; sub(/^[^@]*.echo ...../,"",T); sub(/"$/,"",T); sub(/ .*$/,"",T);
	  if (is_notgt(T)==0) { printf("%s ",T) } }' $BUILDPATH/Makefile`
	msg "XTARGETS: $XTARGETS"

	TARGETS=
	TESTS=
	for i in $XTARGETS
	do
		case $i in
		test*)	TESTS="$TESTS $i";;
		gpt-2*)	GPT2="$GPT2 $i"; TARGETS="$TARGETS $i";;
		*)	TARGETS="$TARGETS $i";;
		esac
	done

	msg "TARGETS: $TARGETS"
	msg "GPT2: $GPT2"
	msg "TESTS: $TESTS"

	return $RET_OK
}
#get_targets; exit 0

# for test, main, examples execution
TESTENV="GGML_NLOOP=1 GGML_NTHREADS=4"

JFKWAV=jfk.wav
NHKWAV=nhk0521-16000hz1ch-0-10s.wav

PROMPTEX="This is an example"
PROMPT="tell me about creating web site in 5 steps:"
#PROMPTJP="京都について教えてください:"
PROMPTJP="あなたは誠実で日本に詳しい観光業者です。京都について教えてください:"
SEEDOPT=1685215400
SEED=

MKCLEAN=$RET_FALSE
NOCLEAN=$RET_FALSE

DIRNAME=
BRANCH=
CMD=

###
# func:do_sync ver: 2024.01.03
# do synchronize remote BRANCH
# do_sync
do_sync()
{
	# in build

	msg "# synchronizing ..."

	if [ x"$BRANCH" = x ]; then
		die $ERR_BADSETTINGS "do_sync: need BRANCH, exit"
	fi

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
}

# func:cp_mk_script ver: 2024.01.01
# do script(FIXBASEyymmdd.sh mk) for create script
# cp_mk_script
do_mk_script()
{
	# in build

	# update fixsh in BASEDIR and save update files
	msg "# creating FIXSH ..."

	local DTNOW DFFIXSH FFIXSH DFIXSH

	DTNOW=`date '+%y%m%d'`
	msg "DTNOW:$DTNOW"


	# to BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}*
		fi
	fi
	DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
	DFIXSH=`get_datefile_date ymd $DFFIXSH`
	FFIXSH=`get_datefile_file $DFFIXSH`
	msg "FIXSH:$FFIXSH"

	# check
	if [ ! x$DTNOW = x"$DFIXSH" ]; then
		msg "sh $FFIXSH mk"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			sh $FFIXSH mk
			if [ ! $? -eq $RET_OK ]; then
				die $? "RETCODE:$?: can't make ${FIXBASE}${DTNOW}.sh, exit"
			fi
			if [ ! -s $FFIXSH ]; then
				rm -f $FFIXSH
				die $ERR_CANTCREATE "size zero, can't create ${FIXBASE}${DTNOW}.sh, exit"				
			fi

			DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
			FFIXSH=`get_datefile_file $DFFIXSH`
			msg "$FFIXSH: created"
			msg "$ ls -l $FFIXSH"
			ls -l $FFIXSH
		fi
	else
		msg "$FFIXSH: already existed, skip"	
	fi

	# back to BUILDPATH
	msg "cd $BUILDPATH"
	cd $BUILDPATH
}

# func:do_cp ver: 2024.01.07
# do copy sd.cpp source,examples files to DIRNAME
# do_cp
do_cp()
{
	# in build

	msg "# copying ..."
	chk_and_cp -p ../CMakeLists.txt $DIRNAME|| die 221 "can't copy files"
	chk_and_cp -pr ../src ../include/ggml $DIRNAME || die 222 "can't copy src files"
	chk_and_cp -pr ../examples $DIRNAME || die 223 "can't copy examples files"
	chk_and_cp -pr ../tests $DIRNAME || die 224 "can't copy tests files"
	msg "find $DIRNAME -name '*.[0-9][0-9][01][0-9][0-3][0-9]*' -exec rm {} \;"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		find $DIRNAME -name '*.[0-9][0-9][01][0-9][0-3][0-9]*' -exec rm {} \;
	fi

	# $ ls -l ggml/build/0521up/examples/mnist/models/mnist/
	#-rw-r--r-- 1 user user 1591571 May 21 22:45 mnist_model.state_dict
	#-rw-r--r-- 1 user user 7840016 May 21 22:45 t10k-images.idx3-ubyte
	msg "rm -r $DIRNAME/examples/mnist/models"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		rm -r $DIRNAME/examples/mnist/models
	fi
}

# func:do_cmk ver: 2024.01.03
# do cmake .. CMKOPT
# do_cmk
do_cmk()
{
	# in build

	if [ x"$CMKOPT" = x ]; then
		die $ERR_BADSETTINGS "do_cmk: need CMKOPT, exit"
	fi

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
	chk_and_cp -p Makefile $DIRNAME/Makefile.build

	# update targets
	msg "get_targets"
	get_targets
}

# func:do_test ver: 2024.01.03
# do make TESTS, then make test, move test exec-files to DIRNAME
# do_test
do_test()
{
	# in build

	if [ x"$TESTS" = x ]; then
		die $ERR_BADSETTINGS "do_tests: need TESTS, exit"
	fi

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

CPSCRIPTFILES=
# func:cp_script ver: 2024.01.03
# copy srcfile to dstfile.yymmdd and dstfile, store dstfiles to CPSCRIPTFILES
# cp_script SRC DST
cp_script()
{
	local SRC DST DFSRC MDSRC DSTDT

	if [ ! $# -ge 2 ]; then
		emsg "cp_script: ARG:$*: need SRC DST, error return"
		return $ERR_NOARG
	fi

	SRC="$1"
	DST="$2"
	xmsg "cp_script: SRC:$SRC"
	xmsg "cp_script: DST:$DST"

	if [ ! -f "$SRC" ]; then
		emsg "cp_script: $SRC: not found, error return"
		return $ERR_NOTEXISTED
	fi
	if [ "$SRC" = "$DST" ]; then
		emsg "cp_script: $SRC: $DST: same file, error return"
		return $ERR_BADARG
	fi

	# DF DstFile
	DFSRC=`get_latestdatefile "$SRC"`
	xxmsg "cp_script: DFSRC:$DFSRC"
	YMDSRC=`get_datefile_date ymd $DFSRC`
	xxmsg "cp_script: YMDSRC:$YMDSRC"
	DSTDT="${DST}.$YMDSRC"
	msg "cp -p \"$SRC\" \"$DSTDT\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DSTDT"
	fi
	msg "cp -p \"$SRC\" \"$DST\""
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p "$SRC" "$DST"
	fi
	CPSCRIPTFILES="$DSTDT $DST"
}
test_cp_script()
{
	local DT OKFILE NGFILE TMPDIR1 OKFILE2 NGFILE2 DF RETCODE

	# set test env
	DT=`date '+%y%m%d'`
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
	func_test_reset

	# test code
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

	# reset test env
	func_test_show
	msg "rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	rm $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
	rmdir $TMPDIR1
	msg "ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*"
	ls -l $OKFILE ${NGFILE}* ${OKFILE2}* ${NGFILE2}*
}
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_TRUE; test_cp_script; exit 0
#msg "test_cp_script"; VERBOSE=2; NOEXEC=$RET_FALSE; test_cp_script; exit 0

# func:git_script ver: 2024.01.03
# git push scripts ymd, UPDATENAME, FIXSHNAME, MKZIPNAME
# git_script
git_script()
{
	# in build

	msg "# git push scripts ..."

	local DT0 ADDFILES COMMITFILES
	local DFUPDATE DFFIXSH DFMKZIP FUPDATE FFIXSH FMKZIP
	local DFUPDATEG DFFIXSHG DFMKZIPG FUPDATEG FFIXSHG FMKZIPG

	# check
	if [ x"$BASEDIR" = x ]; then
		die $ERR_BADSETTINGS "git_script: need path, BASEDIR, exit"
	fi
	if [ x"$TOPDIR" = x ]; then
		die $ERR_BADSETTINGS "git_script: need dirname, TOPDIR, exit"
	fi
	if [ x"${FIXSHNAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need FIXSHNAME, exit"
	fi
	if [ x"${MKZIPNAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need MKZIPNAME, exit"
	fi
	if [ x"${UPDATENAME}" = x ]; then
		die $ERR_BADSETTINGS "git_script: need UPDATENAME, exit"
	fi
	if [ x"$SCRIPT" = x ]; then
		die $ERR_BADSETTINGS "git_script: need branch, SCRIPT, exit"
	fi
	if [ x"$BRANCH" = x ]; then
		die $ERR_BADSETTINGS "git_script: need branch, BRANCH, exit"
	fi
	if [ x"$BUILDPATH" = x ]; then
		die $ERR_BADSETTINGS "git_script: need path, BUILDPATH, exit"
	fi

	DT0=`date '+%y%m%d'`
	msg "DT0:$DT0"

	ADDFILES=""
	COMMITFILES=""

	# to BASEDIR
	msg "cd $BASEDIR"
	cd $BASEDIR
	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
		fi
	fi
	DFUPDATE=`get_latestdatefile "${UPDATENAME}"`
	DFFIXSH=`get_latestdatefile "${FIXSHNAME}*"`
	DFMKZIP=`get_latestdatefile "${MKZIPNAME}"`
	FUPDATE=
	FFIXSH=
	FMKZIP=
	if [ ! x"$DFUPDATE" = x ]; then
		FUPDATE=`get_datefile_file $DFUPDATE`
	fi
	if [ ! x"$DFFIXSH" = x ]; then
		FFIXSH=`get_datefile_file $DFFIXSH`
	fi
	if [ ! x"$DFMKZIP" = x ]; then
		FMKZIP=`get_datefile_file $DFMKZIP`
	fi
	msg "FUPDATE:$FUPDATE"
	msg "FFIXSH:$FFIXSH"
	msg "FMKZIP:$FMKZIP"

	# to TOPDIR
	# move to git SCRIPT branch and sync

	msg "cd $BASEDIR/$TOPDIR"
	cd $BASEDIR/$TOPDIR
	msg "git branch"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git branch
	fi
	msg "git checkout $SCRIPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git checkout $SCRIPT
	fi

	# avoid error: pathspec 'fix1202.sh' did not match any file(s) known to git.
	# avoid  ! [rejected]	script -> script (non-fast-forward)  error: failed to push some refs to 'https://ghp_ ...
	# https://docs.github.com/ja/get-started/using-git/dealing-with-non-fast-forward-errors
	msg "git pull origin $SCRIPT"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git pull origin $SCRIPT
	fi

#	msg "git fetch"
#	if [ $NOEXEC -eq $RET_FALSE ]; then
#		git fetch
#	fi
#	msg "git reset --hard origin/master"
#	if [ $NOEXEC -eq $RET_FALSE ]; then
#		git reset --hard origin/master
#	fi

	if [ $VERBOSE -ge 1 ]; then
		msg "ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			ls -ltr ${FIXSHNAME}* ${MKZIPNAME}* ${UPDATENAME}*
		fi
	fi
	# G means git
	DFUPDATEG=`get_latestdatefile "${UPDATENAME}"`
	DFFIXSHG=`get_latestdatefile "${FIXSHNAME}*"`
	DFMKZIPG=`get_latestdatefile "${MKZIPNAME}"`
	FUPDATEG=
	FFIXSHG=
	FMKZIPG=
	if [ ! x"$DFUPDATEG" = x ]; then
		FUPDATEG=`get_datefile_file $DFUPDATEG`
	fi
	if [ ! x"$DFFIXSHG" = x ]; then
		FFIXSHG=`get_datefile_file $DFFIXSHG`
	fi
	if [ ! x"$DFMKZIPG" = x ]; then
		FMKZIPG=`get_datefile_file $DFMKZIPG`
	fi
	msg "FUPDATEG:$FUPDATEG"
	msg "FFIXSHG:$FFIXSHG"
	msg "FMKZIPG:$FMKZIPG"

	#
	if [ ! x"$FUPDATE" = x ]; then
		if [ x"$FUPDATEG" = x ]; then
			# new copy
			FUPDATEG="$UPDATENAME"
			msg "Nnew: copy: $BASEDIR/$FUPDATE $FUPDATEG"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp_script $BASEDIR/$FUPDATE $FUPDATEG
				#find_latest DTTMSHSTART
				#ADDFILES="$ADDFILES $FUPDATEG"
				#COMMITFILES="$COMMITFILES $FUPDATEG"
				ADDFILES="$ADDFILES $CPSCRIPTFILES"
				COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
			fi
		else
			# check diff, copy
			msg "diff $FUPDATEG $BASEDIR/$FUPDATE"
			if [ $NOEXEC -eq $RET_FALSE ]; then
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
					#find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FUPDATEG"
					#COMMITFILES="$COMMITFILES $FUPDATEG"
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
				fi
			fi
		fi
	fi

	if [ ! x"FFIXSH" = x ]; then
		if [ x"$FFIXSHG" = x ]; then
			# new copy
			msg "new: copy: $BASEDIR/$FFIXSH $FFIXSH"
			msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FFIXSH
				#find_latest DTTMSHSTART
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
			fi
		elif [ ! $FFIXSH = $FFIXSHG ]; then
			# always copy
			msg "always: copy: $BASEDIR/$FFIXSH $FFIXSH"
			msg "cp -p $BASEDIR/$FFIXSH $FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				cp -p $BASEDIR/$FFIXSH $FFIXSH
				#find_latest DTTMSHSTART
				ADDFILES="$ADDFILES $FFIXSH"
				COMMITFILES="$COMMITFILES $FFIXSH"
			fi
		else
			# check diff, copy
			msg "diff $FFIXSHG $BASEDIR/$FFIXSH"
			if [ $NOEXEC -eq $RET_FALSE ]; then
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
					#find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FFIXSHG"
					#COMMITFILES="$COMMITFILES $FFIXSHG"
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
				fi
			fi
		fi
	fi

	if [ ! x"$FMKZIP" = x ]; then
		if [ x"$FMKZIPG" = x ]; then
			# new copy
			FMKZIPG="$MKZIPNAME"
			msg "new: copy: $BASEDIR/$FMKZIP $FMKZIPG"
			cp_script $BASEDIR/$FMKZIP $FMKZIPG
			#find_latest DTTMSHSTART
			#ADDFILES="$ADDFILES $FMKZIPG"
			#COMMITFILES="$COMMITFILES $FMKZIPG"
			ADDFILES="$ADDFILES $CPSCRIPTFILES"
			COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
		else
			# check diff, copy
			msg "diff $FMKZIPG $BASEDIR/$FMKZIP"
			if [ $NOEXEC -eq $RET_FALSE ]; then
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
					#find_latest DTTMSHSTART
					#ADDFILES="$ADDFILES $FMKZIPG"
					#COMMITFILES="$COMMITFILES $FMKZIPG"
					ADDFILES="$ADDFILES $CPSCRIPTFILES"
					COMMITFILES="$COMMITFILES $CPSCRIPTFILES"
				fi
			fi
		fi
	fi

	# git
	msg "ADDFILES:$ADDFILES"
	msg "COMMITFILES:$COMMITFILES"
	if [ ! x"$COMMITFILES" = x ]; then
		if [ ! x"$ADDFILES" = x ]; then
			msg "git add $ADDFILES"
			if [ $NOEXEC -eq $RET_FALSE ]; then
				git add $ADDFILES
			fi
		fi
		msg "git commit -m \"update scripts\" $COMMITFILES"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git commit -m "update scripts" $COMMITFILES
		fi
		msg "git status"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git status
		fi
		msg "git push origin $SCRIPT"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			git push origin $SCRIPT
		fi
	fi

	# back
	msg "git checkout $BRANCH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		git checkout $BRANCH
	fi

	# back to BUILDPATH
	msg "cd $BUILDPATH"
	cd $BUILDPATH
}
#msg "git_script"; NOEXEC=$RET_TRUE; VERBOSE=2; git_script; exit 0

#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
#./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p \"$PROMPT\""
#./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p "$PROMPT" || die 75 "do gpt-j failed"
#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV"
#./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV || die 89 "do whisper failed"

# func:do_bin ver: 2024.01.07
# execute whisper or DOBIN with MODEL, WAVFILE or VARPROMPT, DOOPT
# do_bin DOBIN MODEL VARPROMPT DOOPT
# do_bin DOBIN MODEL WAVFILE DOOPT
do_bin()
{
	local RETCODE MODEL VARPROMPT DOOPT DT PROMPTTXT

	RETCODE=$RET_OK

	if [ x"$DIRNAME" = x ]; then
		emsg "do_bin: need DIRNAME, skip"
		return $ERR_BADSETTINGS
	fi

	if [ x"$1" = x ]; then
		emsg "do_bin: need DOBIN, MODEL, VARPROMPT skip$"
		return $ERR_BADARG
	fi
	DOBIN="$1"
	MODEL="$2"
	VARPROMPT="$3"
	shift 3
	DOOPT="$*"

	DT=`date '+%y%m%d'`

	#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
	#./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p "$PROMPTEX" || die 64 "do gpt-2 failed"
	if [ x"$DOBIN" = x"whisper" ]; then
		WAVFILE=`eval echo '$'${VARPROMPT}`
		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/$DOBIN -m $MODEL $DOOPT -f $WAVFILE
			RETCODE=$?
		fi
		if [ ! $RETCODE -eq $RET_OK ]; then
			emsg "do $DOBIN failed"
		fi
	else
		if [ x"$SEEDOPT" = x ]; then
			emsg "do_bin: need SEEDOPT, skip"
			return $ERR_BADSETTINGS
		fi
		SEED=$SEEDOPT

		PROMPTTXT=`eval echo '$'${VARPROMPT}`

		msg "./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p \"$PROMPTTXT\""
		if [ $NOEXEC -eq $RET_FALSE ]; then
			./$DIRNAME/$DOBIN -m $MODEL $DOOPT -s $SEED -p "$PROMPTTXT"
			RETCODE=$?
		fi
		if [ ! $RETCODE -eq $RET_OK ]; then
			emsg "do $DOBIN failed"
		fi
	fi

	return $RETCODE
}

# func:mk_targets ver: 2024.01.06
# make TARGETS and copy DIRNAME
# mk_targets
mk_targets()
{
	local BINS i

	if [ x"$TARGETS" = x ]; then
		emsg "mk_targets: need TARGETS, skip"
		return $ERR_BADSETTINGS
	fi

	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 280 "make clean failed"
		fi
		MKCLEAN=$RET_TRUE
	fi
	msg "make $TARGETS"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		make $TARGETS || die 281 "make $TARGETS failed"
	fi
	BINS=""; for i in $TARGETS ;do BINS="$BINS bin/$i" ;done
	msg "cp -p $BINS $DIRNAME/"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		cp -p $BINS $DIRNAME || die 282 "can't cp $BINS"
	fi
}

# func:do_gpt2 ver: 2024.01.07
# make gpt-2-ctx, gpt-2* and move DIRNAME, do GPT2BIN
# do_gpt2 [NOMAKE|NOEXEC]
do_gpt2()
{
	# in build

	local DOOPT GPT2BIN GPT2MK GPT2BINS i

	DOOPT="$1"

	# make
	if [ $MKCLEAN -eq $RET_FALSE -a $NOCLEAN -eq $RET_FALSE ]; then
		msg "make clean"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make clean || die 261 "make clean failed"
			MKCLEAN=$RET_TRUE
		fi
	fi

	GPT2BIN=gpt-2-ctx
	GPT2MK=$RET_FALSE
	GPT2BINS=
	for i in $GPT2
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

	if [ ! x"$DOOPT" = x"NOEXEC" -a $NOEXEC -eq $RET_FALSE ]; then
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-f32.bin -s $SEED -p \"$PROMPTEX\""
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-q4_0.bin -s $SEED -p \"$PROMPTEX\""
		#msg "./$DIRNAME/$GPT2BIN -m models/gpt-2-117M/ggml-model-q4_1.bin -s $SEED -p \"$PROMPTEX\""
		chk_level $LEVELSTD do_bin $GPT2BIN models/gpt-2-117M/ggml-model-f32.bin PROMPTEX
		chk_level $LEVELMIN do_bin $GPT2BIN models/gpt-2-117M/ggml-model-q4_0.bin PROMPTEX
		chk_level $LEVELMAX do_bin $GPT2BIN models/gpt-2-117M/ggml-model-q4_1.bin PROMPTEX
	else
		msg "skip executing gpt-2"
	fi
}

# func:do_gptj ver: 2024.01.07
# make gpt-j and gpt-j-quantize and move DIRNAME, do gpt-j
# do_gptj [NOMAKE|NOEXEC]
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

	if [ ! x"$DOOPT" = x"NOEXEC" -a $NOEXEC -eq $RET_FALSE ]; then
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-f16.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_0.bin -s $SEED -p \"$PROMPT\""
		#msg "./$DIRNAME/gpt-j -m models/gpt-j-6B/ggml-model-q4_1.bin -s $SEED -p \"$PROMPT\""
		chk_level $LEVELSTD do_bin $DOBIN models/gpt-j-6B/ggml-model-f16.bin PROMPT
		chk_level $LEVELMIN do_bin $DOBIN models/gpt-j-6B/ggml-model-q4_0.bin PROMPT
		chk_level $LEVELMAX do_bin $DOBIN models/gpt-j-6B/ggml-model-q4_1.bin PROMPT
	else
		msg "skip executing $DOBIN"
	fi
}

# func:do_whisper ver: 2024.01.07
# make whisper and whisper-quantize and move DIRNAME, do whisper
# do_gptj [NOMAKE|NOEXEC]
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

	if [ x"$DOOPT" = x"NOEXEC" -a $NOEXEC -eq $RET_FALSE ]; then
		#msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-base.bin -f $JFKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-base.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l en -m models/whisper/ggml-small.bin -f $JFKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_0.bin -f $NHKWAV"
		#msg "./$DIRNAME/whisper -l ja -m models/whisper/ggml-small-q4_1.bin -f $NHKWAV"
		chk_level $LEVELSTD do_bin $DOBIN models/whisper/ggml-base.bin JFKWAV "-l en"
		chk_level $LEVELMAX do_bin $DOBIN models/whisper/ggml-base.bin NHKWAV "-l ja"
		chk_level $LEVELMIN do_bin $DOBIN models/whisper/ggml-small.bin JFKWAV "-l en"
		chk_level $LEVELMAX do_bin $DOBIN models/whisper/ggml-small.bin NHKWAV "-l ja"
		chk_level $LEVELMIN do_bin $DOBIN models/whisper/ggml-small-q4_0.bin NHKWAV "-l ja"
		chk_level $LEVELMAX do_bin $DOBIN models/whisper/ggml-small-q4_1.bin NHKWAV "-l ja"
	else
		msg "skip executing $DOBIN"
	fi
}

# func:do_gptneox ver: 2024.01.07
# make gpt-neox and gpt-neox-quantize and move DIRNAME, do gpt-neox
# do_gptneox [NOMAKE|NOEXEC]
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
		chk_level $LEVELSTD do_bin $DOBIN models/gpt-neox/ggml-3b-f16.bin PROMPT
		chk_level $LEVELMIN do_bin $DOBIN models/gpt-neox/ggml-3b-q4_0.bin PROMPT
		chk_level $LEVELMAX do_bin $DOBIN models/gpt-neox/ggml-3b-q4_1.bin PROMPT

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-large-q4_0.bin -s $SEED -p "$PROMPTJP""
		chk_level $LEVELMAX do_bin $DOBIN models/cyberagent/ggml-model-calm-large-f32.bin PROMPT
		chk_level $LEVELMAX do_bin $DOBIN models/cyberagent/ggml-model-calm-large-f16.bin PROMPTJP
		chk_level $LEVELMIN do_bin $DOBIN models/cyberagent/ggml-model-calm-large-q4_0.bin PROMPTJP

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-1b-q4_0.bin -s $SEED -p "$PROMPTJP""
		chk_level $LEVELMAX do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-f32.bin PROMPT
		chk_level $LEVELMAX do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-f16.bin PROMPTJP
		chk_level $LEVELMIN do_bin $DOBIN models/cyberagent/ggml-model-calm-1b-q4_0.bin PROMPTJP

		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f32.bin -s $SEED -p "$PROMPT""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-f16.bin -s $SEED -p "$PROMPTJP""
		#msg "./$DIRNAME/gpt-neox -m models/cyberagent/ggml-model-calm-3b-q4_0.bin -s $SEED -p "$PROMPTJP""
		chk_level $LEVELMAX do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-f32.bin PROMPT
		chk_level $LEVELSTD do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-f16.bin PROMPTJP
		chk_level $LEVELMIN do_bin $DOBIN models/cyberagent/ggml-model-calm-3b-q4_0.bin PROMPTJP
	else
		msg "skip executing $DOBIN"
	fi
}

# func:do_dollyv2 ver: 2024.01.07
# make dollyv2 and dollyv2-quantize and move DIRNAME, do dollyv2
# do_dollyv2 [NOEXEC]
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
		chk_level $LEVELMAX do_bin $DOBIN models/dollyv2/ggml-model-f16.bin PROMPT
		chk_level $LEVELMIN do_bin $DOBIN models/dollyv2/ggml-model-15_0.bin PROMPTJP
		# dolly-v2-12b
		#msg "./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p \"$PROMPT\""
		#./$DIRNAME/dollyv2 -m models/dollyv2/int4_fixed_zero.bin -s $SEED -p "$PROMPT" || die 136 "do dollyv2 failed"
		chk_level $LEVELMIN do_bin $DOBIN models/dollyv2/int4_fixed_zero.bin PROMPT
	else
		msg "skip executing $DOBIN"
	fi
}

# func:do_examples ver: 2024.01.07
# make examples and move DIRNAME, do examples
# do_examples [NOMAKE|NOEXEC]
do_examples()
{
	# in build

	local EXOPT BINTESTS

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
		msg "make $TARGETS"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			make $TARGETS || die 52 "make $TARGETS failed"
		fi
		BINTESTS=""; for i in $TARGETS ;do BINTESTS="$BINTESTS bin/$i" ;done
		msg "cp -p $BINTESTS $DIRNAME/"
		if [ $NOEXEC -eq $RET_FALSE ]; then
			cp -p $BINTESTS $DIRNAME || die 53 "can't cp"
			NOCOPY=$RET_TRUE
		fi
	fi

	# exec
	if [ ! x"$EXOPT" = xNOEXEC -a $NOEXEC -eq $RET_FALSE ]; then
		do_gpt2 $EXOPT
		do_gptj $EXOPT
		do_whisper $EXOPT
		do_gptneox $EXOPT
		do_dollyv2 $EXOPT
	fi
}

###
usage()
{
	echo "usage: $MYNAME [-h][-v][-n][-nd][-ncp][-nc][-noavx|avx|avx2][-lv LEVEL][-s SEED] dirname branch cmd"
	echo "options: (default)"
	echo "  -h|--help ... this message"
	echo "  -v|--verbose ... increase verbose message level"
	echo "  -n|--noexec ... no execution, test mode"
	echo "  -nd|--nodie ... no die"
	echo "  -ncp|--nocopy ... no copy"
	echo "  -nc|--noclean ... no make clean"
	#echo "  -up ... upstream, no mod source, skip test-blas0"
	echo "  -noavx|-avx|-avx2 ... set cmake option for no AVX, AVX, AVX2 (AVX)"
	echo "  -lv|--level LEVEL ... set execution level as LEVEL, min. 1 .. max. 5 ($DOLEVEL)"
	echo "  -s|--seed SEED ... set SEED ($SEEDOPT)"
	echo "  dirname ... directory name ex. 0226up"
	echo "  branch ... git branch ex. master, gq, devpr"
	echo "  cmd ... sycpcmktstex sy/sync,cp/copy,cmk/cmake,tst/test,ex/examples"
	echo "  cmd ... sycpcmktstne sy,cp,cmk,tst,ne  ne .. build examples but no exec"
	echo "  cmd ... cpcmkg2gjwhtst cp,cmk,g2,gj,wh,gx,dl,tst gpt-2,gpt-j,whisper,gpt-neox,dollyv2"
	echo "  cmd ... cpcmkn2njwhtst cp,cmk,n2,nj,nh,nx,nd,tst build gpt-j but no exec, gpt-2, ..."
	echo "  cmd ... script .. push $UPDATENAME $MKZIPNAME $FIXSHNAME to remote"
}
# default -avx
#CMKOPT="$CMKOPTAVX"
CMKOPT2=""

###
# options and args
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
	#-up)		TARGETS="$TARGETSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-lv|--level)	shift; DOLEVEL=$1;;
	-s|--seed)	shift; SEEDOPT=$1;;
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
shift 2

xmsg "VERBOSE:$VERBOSE NOEXEC:$NOEXEC NODIE:$NODIE NOCOPY:$NOCOPY"
xmsg "NOCLEAN:$NOCLEAN LEVEL:$DOLEVEL SEED:$SEEDOPT"

###
# setup part

msg "# start"
get_datetime DTTM0
msg "# date time: $DTTM0"

# warning:  Clock skew detected.  Your build may be incomplete.
msg "sudo ntpdate ntp.nict.jp"
if [ $NOEXEC -eq $RET_FALSE ]; then
	sudo ntpdate ntp.nict.jp
fi

# check
if [ $NOEXEC -eq $RET_FALSE ]; then
	if [ ! -d $TOPDIR ]; then
		#die $ERR_NOTEXISTED "# can't find $TOPDIR, exit"
		die $ERR_NOTOPDIR "# can't find $TOPDIR, exit"
	fi
else
	msg "skip check $TOPDIR"
fi
if [ ! -d $BUILDPATH ]; then
	msg "mkdir -p $BUILDPATH"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mkdir -p $BUILDPATH
		if [ ! -d $BUILDPATH ]; then
			#die $ERR_NOTEXISTED "# can't find $BUILDPATH, exit"
			die $ERR_NOBUILDDIR "# can't find $BUILDPATH, exit"
		fi
	fi
fi

msg "cd $BUILDPATH"
cd $BUILDPATH

msg "git branch"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git branch
fi
msg "git checkout $BRANCH"
if [ $NOEXEC -eq $RET_FALSE ]; then
	git checkout $BRANCH
fi

if [ ! -e $DIRNAME ]; then
	msg "mkdir $DIRNAME"
	if [ $NOEXEC -eq $RET_FALSE ]; then
		mkdir $DIRNAME
		if [ ! -e $DIRNAME ]; then
			die $ERR_NOTEXISTED "no directory: $DIRNAME, exit"
		fi
	fi
fi


# main options and cmd loop

xmsg "cmdloop: CMD:$# $*"
while [ $# -gt 0 ];
do
	OPTLOOP=$RET_TRUE
	xmsg "cmdloop: OPTLOOP:$OPTLOOP CMD:$# $*"

	# remove break at *
	case $1 in
	-h|--help)	usage; exit $ERR_USAGE;;
	-v|--verbose)	VERBOSE=`expr $VERBOSE + 1`;;
	-n|--noexec)	NOEXEC=$RET_TRUE;;
	-nd|--nodie)	NODIE=$RET_TRUE;;
	-ncp|--nocopy)	NOCOPY=$RET_TRUE;;
	-nc|--noclean)	NOCLEAN=$RET_TRUE;;
	#-up)		TARGETS="$TARGETSUP";;
	-noavx)		CMKOPT="$CMKOPTNOAVX";;
	-avx)		CMKOPT="$CMKOPTAVX";;
	-avx2)		CMKOPT="$CMKOPTAVX2";;
	-lv|--level)	shift; DOLEVEL=$1;;
	-s|--seed)	shift; SEEDOPT=$1;;
	*)		OPTLOOP=$RET_FALSE;;
	esac

	# check no CMD
	if [ $OPTLOOP -eq $RET_TRUE ]; then
		shift
		xmsg "cmdloop: continue: CMD:$# $*"
		continue
	fi

	CMD="$1"
	xmsg "cmdloop: CMD:$CMD"

	case $CMD in
	*sync*)	do_sync;;
	*sy*)	do_sync;;
	*)	msg "no sync";;
	esac

	case $CMD in
	*copy*)	do_cp;;
	*cp*)	do_cp;;
	*)	msg "no copy";;
	esac

	case $CMD in
	*cmake*)	do_cmk;;
	*cmk*)	do_cmk;;
	*)	msg "no cmake";;
	esac

	case $CMD in
	*test*)	do_test;;
	*tst*)	do_test;;
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

	shift
done


# end part

msg "# end"
get_datetime DTTM1
msg "# date time: $DTTM1"
msg "# done."

# duration
#update-katsu560-sdcpp.sh: # date: 20231229-064933
#update-katsu560-sdcpp.sh: # date: 20231229-145939
DTTMSEC=`diff_datetime $DTTM0 $DTTM1`

# summary
msg "# $MYNAME $ALLOPT"
msg "# date time of start: $DTTM0"
msg "# date time of end:   $DTTM1"
msg "# duration: $DTTMSEC sec"
msg "# output file(s):"
DTTMMIN=`expr $DTTMSEC + 59`
DTTMMIN=`expr $DTTMMIN / 60`
EXCLUDE='^'$BUILDPATH'/(CMakeFiles|Testing|data|examples|master|src|tests)/.*'
msg "find $BUILDPATH -type f \( -cmin -$DTTMMIN -o -mmin -$DTTMMIN \) -regextype awk -not -regex $EXCLUDE -exec ls -l '{}' \;"
find $BUILDPATH -type f \( -cmin -$DTTMMIN -o -mmin -$DTTMMIN \) -regextype awk -not -regex $EXCLUDE -exec ls -l '{}' \;

# end
