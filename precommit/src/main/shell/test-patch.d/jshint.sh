#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# no public APIs here
# SHELLDOC-IGNORE

add_test_type jshint

JSHINT_TIMER=0
JSHINT=${JSHINT:-$(command -v jshint 2>/dev/null)}

function jshint_usage
{
  yetus_add_option "--jshint-cmd=<cmd>" "The 'jshint' command to use (default: ${JSHINT})"
}

## @description  parse maven build tool args
## @replaceable  yes
## @audience     public
## @stability    stable
function jshint_parse_args
{
  declare i

  for i in "$@"; do
    case ${i} in
      --jshint-cmd=*)
        JSHINT=${i#*=}
      ;;
    esac
  done
}

function jshint_filefilter
{
  declare filename=$1

  if [[ ${filename} =~ \.js$ ]] ||
     [[ ${filename} =~ .jshintignore ]] ||
     [[ ${filename} =~ .jshintrc ]]; then
    add_test jshint
  fi
}

function jshint_precheck
{
  if ! verify_command "jshint" "${JSHINT}"; then
    add_vote_table 0 jshint "jshint was not available."
    delete_test jshint
  fi

  cat > "${PATCH_DIR}/jshintreporter.js" << EOF
"use strict";

module.exports = {
  reporter: function (res) {
    var len = res.length;
    var str = "";

    res.forEach(function (r) {
      var file = r.file;
      var err = r.error;

      str += file          + ":" +
             err.line      + ":" +
             err.character + ":" +
             err.code      + ":" +
             err.reason + "\\n";
    });

    if (str) {
      process.stdout.write(str + "\\n" + len + " error" +
        ((len === 1) ? "" : "s") + "\\n");
    }
  }
};
EOF
}

function jshint_logic
{
  declare repostatus=$1
  declare -i count

  pushd "${BASEDIR}" >/dev/null || return 1
  "${JSHINT}" \
    --extract=auto \
    --reporter="${PATCH_DIR}/jshintreporter.js" \
    . \
    > "${PATCH_DIR}/${repostatus}-jshint-result.txt.1"

  # strip the last two lines
  #shellcheck disable=SC2016
  count=$(wc -l "${PATCH_DIR}/${repostatus}-jshint-result.txt.1" | "${AWK}" '{print $1}')
  ((count=count-2))
  head -${count} "${PATCH_DIR}/${repostatus}-jshint-result.txt.1"\
    > "${PATCH_DIR}/${repostatus}-jshint-result.txt"

  popd > /dev/null || return 1
}

function jshint_preapply
{
  if ! verify_needed_test jshint; then
    return 0
  fi

  big_console_header "jshint plugin: ${PATCH_BRANCH}"

  start_clock

  jshint_logic branch

  # keep track of how much as elapsed for us already
  JSHINT_TIMER=$(stop_clock)
  return 0
}

## filename:line:character:code:error msg
function jshint_calcdiffs
{
  column_calcdiffs "$@"
}

function jshint_postapply
{
  declare i
  declare numPrepatch
  declare numPostpatch
  declare diffPostpatch
  declare fixedpatch
  declare statstring

  if ! verify_needed_test jshint; then
    return 0
  fi

  big_console_header "jshint plugin: ${BUILDMODE}"

  start_clock

  # add our previous elapsed to our new timer
  # by setting the clock back
  offset_clock "${JSHINT_TIMER}"

  jshint_logic patch

  calcdiffs \
    "${PATCH_DIR}/branch-jshint-result.txt" \
    "${PATCH_DIR}/patch-jshint-result.txt" \
    jshint \
      > "${PATCH_DIR}/diff-patch-jshint.txt"

  # shellcheck disable=SC2016
  numPrepatch=$(wc -l "${PATCH_DIR}/branch-jshint-result.txt" | ${AWK} '{print $1}')

  # shellcheck disable=SC2016
  numPostpatch=$(wc -l "${PATCH_DIR}/patch-jshint-result.txt" | ${AWK} '{print $1}')

  # shellcheck disable=SC2016
  diffPostpatch=$(wc -l "${PATCH_DIR}/diff-patch-jshint.txt" | ${AWK} '{print $1}')


  ((fixedpatch=numPrepatch-numPostpatch+diffPostpatch))

  statstring=$(generic_calcdiff_status "${numPrepatch}" "${numPostpatch}" "${diffPostpatch}" )

  if [[ ${diffPostpatch} -gt 0 ]] ; then
    add_vote_table -1 jshint "${BUILDMODEMSG} ${statstring}"
    add_footer_table jshint "@@BASE@@/diff-patch-jshint.txt"
    bugsystem_linecomments "jshint" "${PATCH_DIR}/diff-patch-jshint.txt"
    return 1
  elif [[ ${fixedpatch} -gt 0 ]]; then
    add_vote_table +1 jshint "${BUILDMODEMSG} ${statstring}"
    return 0
  fi

  add_vote_table +1 jshint "There were no new jshint issues."
  return 0
}

function jshint_precompile
{
  declare repostatus=$1

  if [[ "${repostatus}" = branch ]]; then
    jshint_preapply
  else
    jshint_postapply
  fi
}
