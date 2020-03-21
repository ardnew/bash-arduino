#!/bin/bash

_arduino-build-root()
{
	echo "$HOME/.tmp/arduino-build"
}

_arduino-build-cache()
{
	build_root=$( _arduino-build-root )
	echo "${build_root}.cache"
}

fqbn()
{
	if [[ $# -eq 0 ]]
	then 
		errcho "== **WARNING** ======================================"
		errcho " no arguments given, will match all supported boards "
		errcho "====================================================="
	fi

	arduino-cli board listall $@ | \
		command grep -oP '([^\s:]+:[^\s:]+:[^\s:]+)'
}

arduino-build-help()
{
	printf "usage:\n"
	printf "\n"
	printf "\t- list all connected boards\n"
	printf "\t\tarduino-build -l\n"
	printf "\n"
	printf "\t- list recognized boards, optionally those matching a pattern\n"
	printf "\t\tarduino-build -a [pattern]\n"
	printf "\n"
	printf "\t- compile sketch, uploading to port if -p is given, verifies with -t.\n"
	printf "\t- uploads without compiling if -u is also given.\n"
	printf "\t- uses current directory if sketch -s is not provided.\n"
	printf "\t\tarduino-build -b fqbn [[-u] [-t] -p port] [-s sketch] [-v level]\n"
	printf "\n"
	printf "\n"
}

arduino-build()
{
	local args arg cmd fqbn port sketch userdir mode cmd upload build cache verbose verify binname

	userdir=$HOME/Development/arduino/sketchbook

	# Trace, Debug, Info, Warning, Error, Fatal, Panic
	verbose="trace"

	while test $# -gt 0
	do
		case "${1}" in
			(-h) arduino-build-help; return 1 ;;
			(-a) cmd="board"; arg="listall" ;;
			(-l) cmd="board"; arg="list" ;;
			(-b) shift; fqbn=$1 ;;
			(-p) shift; port=$1 ;;
			(-u) upload=1 ;;
			(-t) verify=1 ;;
			(-s) shift; sketch=$1 ;;
			(-v) shift; verbose=$1 ;;
			( *) args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ -n $cmd ]] && [[ -n $arg ]]
	then
		if [[ $cmd == "board" ]]
		then
			if [[ $arg == "listall" ]]
			then
				arduino-cli board listall ${args[@]}
				return 0
			elif [[ $arg == "list" ]]
			then
				arduino-cli board list
				return 0
			fi
		fi
	fi

	if [[ -z $fqbn ]]
	then
		if [[ -z $ARDUINO_FQBN ]]
		then
			echo "no board name (-b) provided (and ARDUINO_FQBN not defined)"
			return 1
		fi
		fqbn=$ARDUINO_FQBN
	fi

	mapfile -t matches < <( fqbn 2>/dev/null | grep "$fqbn" )
	if [[ ${#matches[@]} -eq 0 ]]
	then
		echo "unsupported board name: $fqbn"
		return 2
	elif [[ ${#matches[@]} -gt 1 ]]
	then
		echo "ambiguous board name: $fqbn"
		echo "alternatives:"
		for b in ${matches[@]}; do echo "	$b"; done
		return 3
	else
		fqbn=${matches[0]}
	fi

	if [[ -z $sketch ]]
	then
		sketch=$PWD
	fi

	if [[ -d "$sketch" ]]
	then
		base=$( basename "$sketch" )
		if [[ ! -f "${sketch}/${base}.ino" ]]
		then
			echo "sketch not found: ${sketch}/${base}.ino"
			return 4
		fi

	elif [[ -f "$sketch" ]] && [[ "$sketch" =~ \.ino$ ]]
	then
		base=$( basename "$sketch" .ino )
		sketchdir=$( dirname "$sketch" )
		sketchbase=$( basename "$sdir" )
		if [[ "$base" != "$sketchbase" ]]
		then
			echo "invalid sketch name ($base) for directory ($sketchbase): $sketch"
			return 5
		fi
		sketch=$sketchdir
	else
		echo "invalid sketch: $sketch"
		return 6
	fi

	build="$( _arduino-build-root )/${base}"
	cache="$( _arduino-build-cache )/${base}"
	binname=$( printf "%s.%s.%s" "$base" "$fqbn" "bin" | tr ':' '.' )

	local fqbnconfig portconfig buildconfig cacheconfig inputconfig logconfig verifyconfig

	fqbnconfig="--fqbn $fqbn"

	if [[ -n $upload ]]
	then
		if [[ -z $port ]]
		then
			echo "no upload port (-p) provided"
			return 7
		fi
		mode="upload"
		cmd="upload"
		upload=$port
		portconfig="--port $port"
		inputconfig="--input ${sketch}/${binname}"
		[[ -n $verify ]] && verifyconfig="--verify"

	elif [[ -n $port ]]
	then
		mode="compile+upload"
		cmd="compile"
		upload=$port
		portconfig="--upload --port $port"
		buildconfig="--build-path $build"
		cacheconfig="--build-cache-path $cache"
		[[ -n $verify ]] && verifyconfig="--verify"

	else
		mode="compile"
		cmd="compile"
		upload="no"
		buildconfig="--build-path $build"
		cacheconfig="--build-cache-path $cache"
		if [[ -n $verify ]]
		then
			echo "warning: ignoring verify flag (-t) on compile-only"
		fi
	fi

	if [[ -n $verbose ]]
	then
		logconfig="--verbose --log-level $verbose"
	fi

	echo "== SETTINGS ======================================================"
	echo
	echo "  mode           - $mode"
	echo "  board (fqbn)   - $fqbn"
	echo "  upload         - $upload"
	echo "  sketchbook     - $userdir"
	echo "  sketch         - $base"
	echo "  log level      - $verbose"
	echo
	echo "=================================================================="
        echo
	echo "  arduino-cli $cmd"
	[[ -n $logconfig ]] &&
	echo "	$logconfig"
	[[ -n $fqbnconfig ]] &&
	echo "	$fqbnconfig"
	[[ -n $portconfig ]] &&
	echo "	$portconfig"
	[[ -n $verifyconfig ]] &&
	echo "	$verifyconfig"
	[[ -n $buildconfig ]] &&
	echo "	$buildconfig"
	[[ -n $cacheconfig ]] &&
	echo "	$cacheconfig"
	[[ -n $inputconfig ]] &&
	echo "	$inputconfig"
	echo "		$sketch"
	echo
	echo "=================================================================="

	cmd="arduino-cli $cmd $logconfig $fqbnconfig $portconfig $verifyconfig $buildconfig $cacheconfig $inputconfig $sketch"
	echo
	echo "------------------------------------------------------------------"
	printf '$ %s\n' "$cmd"
	echo "------------------------------------------------------------------"
	echo
	$cmd
}

arc-help()
{
	arduino-build-help $@
}

arc()
{
	arduino-build $@
}
