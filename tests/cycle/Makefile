# System Configuration
srcdir = ../..


# Inference Rules

# Macro Defines
PROJ = robocopy_backup

test_root = tmp/$(PROJ).test

#通常のテストを行う場合
#src_dir = src_dir
#test_dir = test_dir
#test_file_1 = test_file_1.txt
#test_file_2 = test_file_2.txt
#dest_dir = dest_dir
#src_list = src_list.txt

#スペースを含むディレクトリをテストする場合
src_dir = src dir
test_dir = test dir
test_file_1 = test file 1.txt
test_file_2 = test file 2.txt
dest_dir = dest dir
src_list = src list.txt

#opt_cut_dirs_num += -C 0
opt_robocopy_dir_options += --robocopy-dir-options="/np /njh /njs /mir"
opt_robocopy_file_options += --robocopy-file-options="/np /njh /njs"

ifdef opt_cut_dirs_num
  robocopy_backup_options += $(opt_cut_dirs_num)
endif
ifdef opt_robocopy_dir_options
  robocopy_backup_options += $(opt_robocopy_dir_options)
endif
ifdef opt_robocopy_file_options
  robocopy_backup_options += $(opt_robocopy_file_options)
endif


# Target List
all: \
				test \

# Test
test: \
	test-CLEAN-ALL-FIRST test-PREPARE-1 \
	test-ROBOCOPY_BACKUP-1 test-SHOW_BACKUP_RESULT-1 test-CHECK_BACKUP_RESULT-1 \
	\
	test-CLEAN-PARTIAL test-PREPARE-2 \
	test-ROBOCOPY_BACKUP-2 test-SHOW_BACKUP_RESULT-2 test-CHECK_BACKUP_RESULT-2 \
	\
	test-CLEAN-ALL-LAST

testclean test-CLEAN-ALL-FIRST test-CLEAN-ALL-LAST:
	@rm -fr "/$(test_root)"

test-CLEAN-PARTIAL:
	@rm -fr "/$(test_root)/$(src_dir)" "/$(test_root)/$(dest_dir)"

test-PREPARE-common-1 test-PREPARE-common-2:
	@mkdir -p                          "/$(test_root)/$(src_dir)/$(test_dir)/"; \
	mkdir -p                           "/$(test_root)/$(dest_dir)/"; \
	echo "test_file_1"               > "/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_1)"; \
	echo "test_file_2"               > "/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_2)"; \

test-PREPARE-1: test-PREPARE-common-1
	echo "/$(test_root)/$(src_dir)/" > "/$(test_root)/$(src_list)"

test-PREPARE-2: test-PREPARE-common-2
	echo "/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_1)" > "/$(test_root)/$(src_list)"

test-ROBOCOPY_BACKUP-1 test-ROBOCOPY_BACKUP-2:
	$(srcdir)/robocopy_backup.sh $(robocopy_backup_options) "/$(test_root)/$(src_list)" "/$(test_root)/$(dest_dir)"
	@echo "-I \"$@\" has ended successfully." ; echo

test-SHOW_BACKUP_RESULT-1 test-SHOW_BACKUP_RESULT-2:
	@echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"; \
	(eval "set -x; find \"/$(test_root)/$(dest_dir)\" -print0 | sort -z | xargs -0 -r ls -ald"); \
	echo "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

test-CHECK_BACKUP_RESULT-1:
	@# src_list に記載されたsrc_dir 配下全体がバックアップされたことを確認
	diff -qr "/$(test_root)/$(src_dir)/" "/$(test_root)/$(dest_dir)/$(test_root)/$(src_dir)/"

test-CHECK_BACKUP_RESULT-2:
	@# src_list に記載されたtest_file_1 のみバックアップされたことを確認
	diff -q  "/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_1)" "/$(test_root)/$(dest_dir)/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_1)"
	@# src_list に記載されていないtest_file_2 はバックアップされていないことを確認
	test ! -f "/$(test_root)/$(dest_dir)/$(test_root)/$(src_dir)/$(test_dir)/$(test_file_2)"

