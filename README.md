# robocopy_backup

## 概要

robocopy バックアップ

このツールは、指定された同期元リストに従って、
robocopyコマンドを使用したバックアップを行います。

## 使用方法

### robocopy_backup.sh

このツールで使用可能な同期元リスト(SRC_LIST.txt)を作成します。

    # cat SRC_LIST.txt
    /cygdrive/c/any_dir/
    /cygdrive/c/any_file

同期元リスト(SRC_LIST.txt)に記述されたディレクトリ・ファイルを、
同期先ディレクトリ(DEST_DIR)配下にバックアップします。

    # robocopy_backup.sh -C 1 --robocopy-dir-options="/np /njh /njs /mir" --robocopy-file-options="/np /njh /njs" SRC_LIST.txt DEST_DIR

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* robocopy
* [common_sh](https://github.com/yuksiy/common_sh)

## インストール

ソースからインストールする場合:

    (Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/robocopy_backup>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/robocopy_backup/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2017 Yukio Shiiya
