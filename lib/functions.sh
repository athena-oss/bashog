BASHOG_INSTALL_DIR="$(pwd)/vendor"
BASHOG_AUTOLOADER="$BASHOG_INSTALL_DIR/autoloader.sh"
BASHOG_COLOR_RED=31
BASHOG_COLOR_GREEN=32
BASHOG_COLOR_BLUE=94
BASHOG_COLOR_YELLOW=43

# This function prints a message with the given color code and type.
# USAGE: bashog.print <color_code> <type> <message>
# RETURNS: --
function bashog.print()
{
	local color=$(printf "\033[$1m")
	local normal=$(printf "\033[m")
	printf "%s%b%s\n" "${color}" "[$2]$normal " "$3"
}

# This function prints an ok message.
# USAGE: bashog.print_ok <message>
# RETURNS: --
function bashog.print_ok()
{
	bashog.print "$BASHOG_COLOR_GREEN" "OK" "$1"
}

# This function prints an error message and exits with code 1.
# USAGE: bashog.print_error <message>
# RETURNS: --
function bashog.print_error()
{
	bashog.print "$BASHOG_COLOR_RED" "ERROR" "$1"
	exit 1
}

# This function prints a warning  message and exits with code 1.
# USAGE: bashog.print_warn <message>
# RETURNS: --
function bashog.print_warn()
{
	bashog.print "$BASHOG_COLOR_YELLOW" "WARN" "$1"
}

# This function prints an info message.
# USAGE: bashog.print_info <message>
# RETURNS: --
function bashog.print_info()
{
	bashog.print "$BASHOG_COLOR_BLUE" "INFO" "$1"
}

# This function checks if the given argument is a valid absolute path to a directory
# or file. If not, execution is stopped and an error message is thrown. Otherwise the
# absolute path is returned.
# USAGE:  bashog.absolutepath <file or directory name>
# RETURN: string
function bashog.absolutepath()
{
	if [[ -z "$1" ]]; then
		return 1
	fi

	local dir
	dir=$(dirname "$1")
	if [ ! -d "$dir" ]; then
		bashog.print_error "'$dir' does not exist!"
		return 1
	fi

	local path
	path=$(cd "$dir" && pwd)/$(basename "$1")
	if test ! -f "$path" && test ! -d "$path"; then
		bashog.print_error "'$path' does not exist!"
		return 1
	fi
	echo "$path"
	return 0
}

# This function installs all the dependencies and creates the autoloader in the end.
# USAGE: bashog.run <feed_file>
# RETURNS: 0 (succeeded), 1 (failed)
function bashog.run()
{
	bashog.print_info "Fetching all dependencies..."
	local -a libs=()
	local -a properties=()
	bashog.parse_config "$1" properties
	for line in "${properties[@]}"
	do
		dep=$(echo $line | awk -F"|" '{ print $1 }')
		url=$(echo $line | awk -F"|"  '{ print $2 }')
		version=$(echo $line | awk -F"|"  '{ print $3 }')
		libs+=("$(echo $line | awk -F"|" '{ print $1"/"$4 }')")
		bashog.fetch "$dep" "$url" "$version"
	done

	bashog.create_autoloader "${libs[@]}"
	bashog.print_ok "All dependencies were fetched."
}

# This function fetches the specified dependency.
# USAGE: bashog.fetch <name> <url|organization/repo_name> [<version>]
# RETURNS: 0 (succeeded), 1 (failed)
function bashog.fetch()
{
	if [ -z "$1" ]; then
		bashog.print_error "Dependency NAME not specified!"
	fi

	if [ -z "$2" ]; then
		bashog.print_error "Dependency URL not specified!"
	fi

	bashog.print_info "Fetching '$1'"

	# ensure that vendor dir exists
	if [ ! -d "${BASHOG_INSTALL_DIR}" ]; then
		mkdir ${BASHOG_INSTALL_DIR}
	fi

	local rc=0
	case "$2" in
		*.git)
			bashog.fetch_from_git "$2"
			;;
		*/*)
			if [ -z "$3" ]; then
				bashog.print_error "Dependency VERSION not specified!"
			fi
			bashog.fetch_from_repo "$1" "$2" "$3"
			;;
	esac
	rc=$?

	if [ $rc -ne 0 ]; then
		bashog.print_error "There was a problem fetching the dependencies!"
	fi

	return $rc
}

# This function retrieves the dependency using either curl or wget.
# USAGE: bashog.fetch_from_repo <name> <organization/repo> <version>
# RETURNS: 0 (suceeded), 1 (failed)
function bashog.fetch_from_repo()
{
	local url="https://github.com/$2/archive/v$3.tar.gz"
	local workdir=$(pwd)
	local rc=0
	# download using wget
	cd "${BASHOG_INSTALL_DIR}"
	if which wget 1>/dev/null 2>/dev/null ; then
		wget -q -O - "$url" | tar xz &&  mv "${1}-${3}" "$1"
	# download using curl
	elif which curl 1>/dev/null 2>/dev/null; then
		curl -sL "$url" | tar xz && mv "${1}-${3}" "$1"
	else
		bashog.print_error "You need to install either wget or curl!"
	fi
	rc=$?
	cd "$workdir"
	return $rc
}

# This function retrieves the dependency using git.
# USAGE: bashog.fetch_from_repo <url>
# RETURNS: 0 (suceeded), 1 (failed)
function bashog.fetch_from_git()
{
	if ! which git 1>/dev/null 2>/dev/null; then
		bashog.print_error "git is not installed"
	fi

	local workdir=$(pwd)
	local rc
	cd "${BASHOG_INSTALL_DIR}"
	git clone --depth 1 "$1" 1>/dev/null 2>/dev/null
	rc=$?
	cd "$workdir"
	return $rc
}

# This function creates the autoloader using the specified lib directories.
# USAGE: bashog.create_autoloader <lib...>
# RETURNS: 0 (succeeded), 1 (failed)
function bashog.create_autoloader()
{
	local content="$(cat <<EOF
function bashog.load()
{
	local script=\$1
	shift
	source ${BASHOG_INSTALL_DIR}/\$script
}

EOF
)"
	echo "$content" > "$BASHOG_AUTOLOADER"
	local -a libs=("$@")
	for lib in "${libs[@]}"
	do
		if [ ! -d "${BASHOG_INSTALL_DIR}/$lib" ]; then
			bashog.print_error "Library directory not found '$lib'"
		fi
		for file in $(find "${BASHOG_INSTALL_DIR}/$lib" -type f | grep -v "bootstrap.sh")
		do
			if grep "^function" "$file" 1>/dev/null 2>/dev/null; then
				file=${file//$BASHOG_INSTALL_DIR\//}
				echo "bashog.load \"$file\"" >> "$BASHOG_AUTOLOADER"
			fi
		done
	done
}

# This function parses the configuration file and converts it into an array
# with pipe separated fields.
# USAGE: bashog.parse_config <filename> <array_name>
# RETURN: 0 (succeeded), 1 (failed)
function bashog.parse_config()
{
	if [ ! -f "$1" ]; then
		bashog.print_error "File '$1' does not exist"
	fi

	if [ -z "$2" ]; then
		bashog.print_error "You must specify an array to store the properties"
	fi

	local -a local_array=()
	local -a local_properties=()
	local -i idx=-1
	local tmp
	# idx=2 is reserved for version
	local_array[2]=
	while read line
	do
		case $line in
			"["*)
				if [ $idx -ge 0 ]; then
					# join elements by |
					local IFS="|"
					local_properties[$idx]="${local_array[*]}"
					local_array=()
					local_array[2]=
				fi
				tmp=${line//[/}
				local_array[0]=${tmp//]/}
				((idx++))
				;;
			"url="*)
				local_array[1]="${line//url=/}"
				;;
			"version="*)
				local_array[2]="${line//version=/}"
				;;
			"lib_dir="*)
				local_array[3]="${line//lib_dir=/}"
				;;
		esac
	done < "$1"

	# last section
	if [ $idx -ge 0 ]; then
		# join elements by |
		local IFS="|"
		local_properties[$idx]="${local_array[*]}"
	fi

	eval "$2=( \"\${local_properties[@]}\" )"
}
