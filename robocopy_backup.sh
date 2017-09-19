#!/bin/sh

# ==============================================================================
#   機能
#     同期元リストに従ってROBOCOPY によるバックアップを実行する
#   構文
#     USAGE 参照
#
#   Copyright (c) 2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 関数定義
######################################################################
CMD_V() {
	echo "+ $*"
	if [ "${FLAG_OPT_NO_PLAY}" = "TRUE" ];then
		return $?
	fi
	eval "$*"
	return $?
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    robocopy_backup.sh [OPTIONS ...] SRC_LIST DEST_DIR
		
		    SRC_LIST : Specify a ROBOCOPY source list.
		    DEST_DIR : Specify a destination directory for ROBOCOPY.
		
		OPTIONS:
		    -n (no-play)
		       Print the commands that would be executed, but do not execute them.
		    -C CUT_DIRS_NUM (cut-dirs-number)
		       Specify the number of directory components you want to ignore.
		    --robocopy-dir-options="ROBOCOPY_DIR_OPTIONS ..."
		    --robocopy-file-options="ROBOCOPY_FILE_OPTIONS ..."
		       Specify options which execute robocopy command with.
		       The former is applied when the entry in the source list ends with "/".
		       The latter is applied when the entry in the source list DOES NOT end
		       with "/".
		       See also "robocopy /?" for the further information on each option.
		    --robocopy-error-rc=ROBOCOPY_ERROR_RC
		       Return code of robocopy that is greater than or equal to
		       ROBOCOPY_ERROR_RC is regarded as an error.
		       Specify an integer in the range from 1 to 16 as ROBOCOPY_ERROR_RC.
		       The default is 4.
		    --help
		       Display this help and exit.
	EOF
}

. is_numeric_function.sh

######################################################################
# 変数定義
######################################################################
# ユーザ変数

# システム環境 依存変数
ROBOCOPY="robocopy"
CMD_MKDIR="cmd /c mkdir"

# プログラム内部変数
FLAG_OPT_NO_PLAY=FALSE
CUT_DIRS_NUM="0"

ROBOCOPY_DIR_OPTIONS=""
ROBOCOPY_FILE_OPTIONS=""

# ROBOCOPY が何らかのエラーで正常終了しなかった場合
#   (「rktools.exe/rktools.msi/robocopy.doc」より抜粋)
#     Return Code
#       16  Serious error.
#       8   Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded).
#       4   Some Mismatched files or directories were detected.
#       2   Some Extra files or directories were detected.
#       1   One or more files were copied successfully (that is, new files have arrived).
#       0   No errors occurred, and no copying was done.
ROBOCOPY_ERROR_RC=4

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o nC: -l robocopy-dir-options:,robocopy-file-options:,robocopy-error-rc:,help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-n)	FLAG_OPT_NO_PLAY=TRUE ; shift 1;;
	-C|--robocopy-error-rc)
		# 指定された文字列が数値か否かのチェック
		IS_NUMERIC "$2"
		if [ $? -ne 0 ];then
			echo "-E argument to \"${opt}\" not numeric -- \"$2\"" 1>&2
			USAGE;exit 1
		fi
		case ${opt} in
		-C)	CUT_DIRS_NUM="$2" ; shift 2;;
		--robocopy-error-rc)
			if [ \( $2 -lt 1 \) -o \( $2 -gt 16 \) ];then
				echo "-E argument to \"${opt}\" out of range -- \"$2\"" 1>&2
				USAGE;exit 1
			fi
			ROBOCOPY_ERROR_RC="$2" ; shift 2
			;;
		esac
		;;
	--robocopy-dir-options)	ROBOCOPY_DIR_OPTIONS="$2" ; shift 2;;
	--robocopy-file-options)	ROBOCOPY_FILE_OPTIONS="$2" ; shift 2;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing 1st argument" 1>&2
	USAGE;exit 1
else
	SRC_LIST="$1"
	# バックアップ元リストのチェック
	if [ ! -f "${SRC_LIST}" ];then
		echo "-E SRC_LIST not a file -- \"${SRC_LIST}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 第2引数のチェック
if [ "$2" = "" ];then
	echo "-E Missing 2nd argument" 1>&2
	USAGE;exit 1
else
	DEST_DIR="$(echo "$2" | sed 's,/$,,')"
	# バックアップ先ディレクトリのチェック
	if [ ! -d "${DEST_DIR}" ];then
		echo "-E DEST_DIR not a directory -- \"${DEST_DIR}\"" 1>&2
		USAGE;exit 1
	fi
fi

# 処理開始メッセージの表示
echo
echo "-I robocopy backup has started."

#####################
# メインループ 開始 #
#####################
backup_count=0
warning_count=0
error_count=0

# バックアップ元(src)のループ
while read src ; do
	# コメントと空行は無視
	echo "${src}" | grep -q -e '^#' -e '^$'
	if [ $? -ne 0 ];then
		########################################
		# バックアップ元(src)のチェック
		########################################
		src_path="${src}"
		# src_path が存在しない場合、警告を表示する。
		# (例：src_path="/dir1/dir2")
		if [ \( ! -d "${src_path}" \) -a \( ! -f "${src_path}" \) -a \( ! -h "${src_path}" \) ];then
			warning_count=`expr ${warning_count} + 1`
			echo "-W \"${src_path}\" backup source not exist, skipped" 1>&2
			continue
		fi
		########################################
		# バックアップ元ディレクトリ(src_dir)の取得
		########################################
		# src_path の終端が「/」である場合
		# (例：src_path="/dir1/dir2/")
		echo "${src_path}" | grep -q '/$'
		if [ $? -eq 0 ];then
			src_dir="${src_path}"
			src_file=""
		# src_path の終端が「/」でない場合
		# (例：src_path="/dir1/file1")
		else
			# src_path の親ディレクトリを取得(dirname)し、末尾に"/" を付加する。
			src_dir="$(dirname "${src_path}")/"
			# src_path のファイル名を取得(basename)する。
			src_file="$(basename "${src_path}")"
		fi
		# CUT_DIRS_NUM オプションが指定されている場合
		if [ ${CUT_DIRS_NUM} -ne 0 ];then
			# src_dir の先頭からCUT_DIRS_NUM 個分のディレクトリを削除
			cut_dirs_count=0
			while [ ${cut_dirs_count} -lt ${CUT_DIRS_NUM} ];do
				# src_dir が最短(="/") になっていない場合
				if [ "${src_dir}" != "/" ];then
					cut_dirs_count=`expr ${cut_dirs_count} + 1`
					# src_dir の先頭から1個分のディレクトリを削除
					src_dir="$(echo "${src_dir}" | sed 's,^/[^/]*/,/,')"
				# src_dir が最短(="/") になってしまった場合
				else
					# ループ脱出
					break
				fi
			done
		fi
		########################################
		# バックアップ先ディレクトリ(dest_dir)の取得
		########################################
		# src_dir の先頭に「DEST_DIR」を付加する。
		dest_dir="${DEST_DIR}${src_dir}"
		########################################
		# バックアップ先ディレクトリ(dest_dir_win)の取得
		########################################
		dest_dir_win="$(echo "${dest_dir}" | sed 's,/$,,')"
		dest_dir_win="$(cygpath -w "${dest_dir_win}")"
		# dest_dir が存在しない場合、dest_dir_win を作成する。
		if [ ! -d "${dest_dir}" ];then
			CMD_V "${CMD_MKDIR} \"${dest_dir_win}\""
			if [ $? -ne 0 ];then
				error_count=`expr ${error_count} + 1`
				echo "-E Error has detected, skipped" 1>&2
				continue
			fi
		fi
		########################################
		# バックアップ元(src_win)の取得
		########################################
		src_win="$(echo "${src}" | sed 's,/$,,')"
		if [ ! "${src_file}" = "" ];then
			src_win="$(dirname "${src_win}")"
		fi
		src_win="$(cygpath -w "${src_win}")"
		########################################
		# ROBOCOPY の実行
		########################################
		if [ "${src_file}" = "" ];then
			CMD_V "${ROBOCOPY} ${ROBOCOPY_DIR_OPTIONS} \"${src_win}\" \"${dest_dir_win}\""
		else
			CMD_V "${ROBOCOPY} ${ROBOCOPY_FILE_OPTIONS} \"${src_win}\" \"${dest_dir_win}\" \"${src_file}\""
		fi
		ROBOCOPY_RC=$?
		echo "-I 'robocopy' command return code was \"${ROBOCOPY_RC}\"."
		if [ ${ROBOCOPY_RC} -ge ${ROBOCOPY_ERROR_RC} ];then
			error_count=`expr ${error_count} + 1`
			echo "-E Error has detected, skipped" 1>&2
			continue
		else
			backup_count=`expr ${backup_count} + 1`
			echo "-I \"${src}\" backup has ended successfully."
			continue
		fi
	fi
done < "${SRC_LIST}"
#####################
# メインループ 終了 #
#####################

# 統計の表示
echo
echo "Total of backup count  : ${backup_count}"
echo "----------------------------------------"
echo "Total of warning count : ${warning_count}"
echo "Total of error count   : ${error_count}"

# 処理終了メッセージの表示
if [ \( ${warning_count} -ne 0 \) -o \( ${error_count} -ne 0 \) ];then
	echo
	echo "-E Total of warning or error count was not 0." 1>&2
	echo "-E robocopy backup has ended unsuccessfully." 1>&2
	exit 1
else
	echo
	echo "-I robocopy backup has ended successfully."
	# 作業終了後処理
	exit 0
fi

