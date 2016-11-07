function testcase_bashog.parse_config()
{
	bashunit.test.assert_exit_code.expects_fail "bashog.parse_config"

	local tmpfile=$(bashunit.test.create_tempfile)

	local -a properties=()
	local -a expected=()
	bashog.parse_config "$tmpfile" properties
	bashunit.test.assert_array expected properties

	# with one element
	echo "[dependency_a]" > $tmpfile
	echo "url=https://github.com/athena-oss/bashog.git" >> $tmpfile
	echo "lib_dir=lib/" >> $tmpfile
	expected+=("dependency_a|https://github.com/athena-oss/bashog.git||lib/")
	bashog.parse_config "$tmpfile" properties
	bashunit.test.assert_array expected properties

	# now with 2 elements
	echo "[dependency_b]" >> $tmpfile
	echo "url=https://github.com/athena-oss/bashunit.git" >> $tmpfile
	echo "lib_dir=dir_lib/" >> $tmpfile
	properties=()
	expected+=("dependency_b|https://github.com/athena-oss/bashunit.git||dir_lib/")
	bashog.parse_config "$tmpfile" properties
	bashunit.test.assert_array expected properties

	# now with element with version
	echo "[dependency_c]" >> $tmpfile
	echo "url=athena-oss/plugin-php" >> $tmpfile
	echo "version=2.0" >> $tmpfile
	echo "lib_dir=dir_lib/" >> $tmpfile
	properties=()
	expected+=("dependency_c|athena-oss/plugin-php|2.0|dir_lib/")
	bashog.parse_config "$tmpfile" properties
	bashunit.test.assert_array expected properties


	rm $tmpfile
}

function testcase_bashog.fetch()
{
	bashunit.test.mock.returns "bashog.print_info" 0

	bashunit.test.assert_exit_code.expects_fail "bashog.fetch"
	bashunit.test.assert_exit_code.expects_fail "bashog.fetch" "mydep"

	bashunit.test.mock.outputs "bashog.fetch_from_git" "FROM GIT"
	bashunit.test.assert_output "bashog.fetch" "FROM GIT" "mydep" "https://github.com/athena-oss/bashog.git"

	bashunit.test.assert_exit_code.expects_fail "bashog.fetch" "mydep" "athena-oss/bashog"

	bashunit.test.mock.outputs "bashog.fetch_from_repo" "FROM REPO"
	bashunit.test.assert_output "bashog.fetch" "FROM REPO" "mydep" "athena-oss/bashog" "v2.0.3"
}
