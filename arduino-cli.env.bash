#!/bin/bash

arduino-cli-config-file()
{
	echo "$HOME/.config/arduino-cli/config.yaml"
}

_arduino-cli-config-file-exists()
{
	local path="$( arduino-cli-config-file )"
	[[ -f "$path" ]] && return 0
	{
		echo "== **ERROR** ======================"
		echo " arduino-cli config file not found "
		echo "==================================="
		echo "-> $path"
	} >&2
	return 1
}

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
	_arduino-cli-config-file-exists || return 1
	local config="--config-file $( arduino-cli-config-file )"

	if [[ $# -eq 0 ]]
	then 
		{
			echo "== **WARNING** ======================================"
			echo " no arguments given, will match all supported boards "
			echo "====================================================="
		} >&2
	fi

	arduino-cli board listall $config $@ | \
		command grep -oP '([^\s:]+:[^\s:]+:[^\s:]+)'
}

_arduino-env-file()
{
	echo ".arduino.env"
}

ino-help()
{

	printf "usage:\n"
	printf "\n"
	printf "\tino -l\n"
	printf "\tino -a [PATTERN]\n"
	printf "\tino -b FQBN [-p PORT [-u] [-t]] [-s SKETCH] [-v LEVEL] [-w]\n"
	printf "\tino cli ...\n"
	printf "\n"
	printf "\n"
	printf "options:\n"
	printf "\n"
	printf "\t-l              - list all boards connected to the system\n"
	printf "\n"
	printf "\t-a [PATTERN]    - list all known fully-qualified board names, optionally filtered\n"
	printf "\t                  by those matching PATTERN\n"
	printf "\n"
	printf "\t-b FQBN         - use board with given FQBN\n"
	printf "\n"
	printf "\t-p PORT         - upload to device connected to serial port at path PORT\n"
	printf "\n"
	printf "\t-u              - upload without recompiling (requires: -p)\n"
	printf "\n"
	printf "\t-t              - verify executable after uploading (requires: -p)\n"
	printf "\n"
	printf "\t-s SKETCH       - compile/upload sketch at path SKETCH, or uses \$PWD if -s option\n"
	printf "\t                  is not provided\n"
	printf "\n"
	printf "\t-v LEVEL        - use verbosity LEVEL (trace debug info warning error fatal panic)\n"
	printf "\n"
	printf "\t-w              - write configuration to file for use with autoconfig (-x)\n"
	printf "\n"
	printf "\t-x              - use FQBN/PORT in configuration file defined in sketch directory\n"
	printf "\n"
	printf "\tcli ...         - invoke arduino-cli, passing all arguments on as subcommands, but\n"
	printf "\t                  using the configuration file associated with this environment\n"
	printf "\n"
	printf "\n"

	_arduino-cli-config-file-exists
}

ino()
{
	_arduino-cli-config-file-exists || return 1

	local args arg cmd cli config fqbn port sketch userdir mode cmd upload build cache verbose verify binname writeconf autoconf

	config="--config-file $( arduino-cli-config-file )"
	userdir=$HOME/Development/arduino/sketchbook

	# Trace, Debug, Info, Warning, Error, Fatal, Panic
	verbose="trace"

	while test $# -gt 0
	do
		case "${1}" in
		(-h)	ino-help; return 1 ;;
		(-a)	cmd="board"; arg="listall" ;;
		(-l)	cmd="board"; arg="list" ;;
		(-b)	shift; fqbn=$1 ;;
		(-p)	shift; port=$1 ;;
		(-u)	upload=1 ;;
		(-t)	verify=1 ;;
		(-s)	shift; sketch=$1 ;;
		(-v)	shift; verbose=$1 ;;
		(-w)	writeconf=1 ;;
		(-x)	autoconf=1 ;;
		(cli)	shift; cli=1; break ;;
		(*)	args=( "${args[@]}" "$1" ) ;;
		esac
		shift
	done

	if [[ -n $cli ]]
	then
		cmd="arduino-cli $config"
		arg="$@"
		echo
		echo "------------------------------------------------------------------"
		printf '$ %s\n' "$cmd $arg"
		echo "------------------------------------------------------------------"
		echo
		$cmd "$@"
		return
	fi

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
			return 1
		fi

	elif [[ -f "$sketch" ]] && [[ "$sketch" =~ \.ino$ ]]
	then
		base=$( basename "$sketch" .ino )
		sketchdir=$( dirname "$sketch" )
		sketchbase=$( basename "$sdir" )
		if [[ "$base" != "$sketchbase" ]]
		then
			echo "invalid sketch name ($base) for directory ($sketchbase): $sketch"
			return 2
		fi
		sketch=$sketchdir
	else
		echo "invalid sketch: $sketch"
		return 3
	fi

	if [[ -n $autoconf ]]
	then
		envfile="$sketch/$( _arduino-env-file )"
		if [[ -f "$envfile" ]]
		then
			. "$envfile"
			[[ -n $FQBN ]] && ARDUINO_FQBN=$FQBN
			[[ -n $PORT ]] && ARDUINO_PORT=$PORT
		fi
	fi

	if [[ -z $fqbn ]]
	then
		if [[ -z $ARDUINO_FQBN ]]
		then
			echo "no board name (-b) provided (and ARDUINO_FQBN not defined)"
			return 4
		fi
		fqbn=$ARDUINO_FQBN
	fi

	if [[ -z $port ]]
	then
		port=$ARDUINO_PORT
	fi

	mapfile -t matches < <( fqbn 2>/dev/null | grep "$fqbn" )
	if [[ ${#matches[@]} -eq 0 ]]
	then
		echo "unsupported board name: $fqbn"
		return 5
	elif [[ ${#matches[@]} -gt 1 ]]
	then
		echo "ambiguous board name: $fqbn"
		echo "alternatives:"
		for b in ${matches[@]}; do echo "	$b"; done
		return 6
	else
		fqbn=${matches[0]}
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

	if [[ -n $writeconf ]]
	then
		cat <<__AUTOCONF__ > "$sketch/$( _arduino-env-file )"
# automatically generated - edit if you want i guess
FQBN=$fqbn
PORT=$port
__AUTOCONF__
	fi

	if [[ -n $verbose ]]
	then
		logconfig="--verbose --log-level $verbose"
	fi

	echo "== SETTINGS ======================================================"
	echo
	echo "  config         - $config"
	echo "  mode           - $mode"
	echo "  board (fqbn)   - $fqbn"
	echo "  upload         - $upload"
	echo "  sketchbook     - $userdir"
	echo "  sketch         - $base"
	echo "  log level      - $verbose"
	echo
	echo "=================================================================="
        echo
	echo "  arduino-cli $config $cmd"
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

	cmd="arduino-cli $config $cmd $logconfig $fqbnconfig $portconfig $verifyconfig $buildconfig $cacheconfig $inputconfig $sketch"
	echo
	echo "------------------------------------------------------------------"
	printf '$ %s\n' "$cmd"
	echo "------------------------------------------------------------------"
	echo
	$cmd
}
