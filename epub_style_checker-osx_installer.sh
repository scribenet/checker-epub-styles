#!/bin/bash

OSX_CLI_TOOLS_INSTALL_METHOD_ALT=0
OSX_VER_MINOR_MINIMUM="7"
INSTALL_DIR_ROOT="${HOME}/.checker/"
INSTALL_DIR_ESC="/epub_styles/"
GIT_CLONE_PATH="https://github.com/scribenet/checker-epub-styles.git"

function out_welcome() 
{
	echo -en "E-PUB STYLES CHECKER\n\n"
}

function out_description() 
{
	echo -en "\nThis will install the following applications:\n" \
	" - XCode Command Line Tools (https://developer.apple.com/downloads)\n" \
	" - Homebrew (https://brew.sh)\n" \
	" - Ruby 2.1 (and gem dependencies)\n" \
	" - E-Pub Styles Checker\n\n"
	make_continue_prompt
}

function make_continue_prompt()
{
	echo -en "CONTINUE? (Press \"CONTROL+c\" to cancel) [yes]: "
	read
}

function do_check_osx_version() 
{
	OSX_VER_FULL="$(sw_vers -productVersion)"
	local ver_tmp="${OSX_VER_FULL#*"."}"
	OSX_VER_MINOR="${ver_tmp%%"."*}"
	echo "Determining compatibility..."
	echo -en " - Found OSX ${OSX_VER_FULL}: "

	if [ "${OSX_VER_MINOR}" -gt "$(((${OSX_VER_MINOR_MINIMUM} - 1)))" ]; then
		echo "Supported."
	else
		echo "Not supported! Exiting..."
		exit -1
	fi
}

function do_install_cli_tools()
{
	if [ "${OSX_CLI_TOOLS_INSTALL_METHOD_ALT}" == 1 ]; then
		do_install_cli_tools_dl
	else
		do_install_cli_tools_native
	fi
}

function do_install_cli_tools_native()
{
	echo -en "\nINSTALLING: X-Code Command Line Tools (Native Method)\n" \
		" - Please use the pop-up dialog to select \"Install\"\n" \
		" - Once that process has completed, press [ENTER]\n\n"
	xcode-select --install > /dev/null 2>&1
	local xcode_select_ret=$?
	if [ "${xcode_select_ret}" != 0 ]; then
		echo -en "ACTION: One of the following occurred:\n" \
			" 1. An error occurred during the installation.\n" \
			" 2. You already have the X-Code Command Line Tools installed.\n\n"
		echo -en "It is safe to continue regardless: the script will fail later in the\nevent of the former (1)" \
			"without causing any harm to your system.\n\n"
		make_continue_prompt
	else
		make_continue_prompt
	fi
}

function do_homebrew_install()
{
	echo -en "\nINSTALLING: Homebrew\n\n"
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function do_homebrew_update()
{
	echo -en "\nACTION: Updating homebrew package database..."
	brew update > /dev/null 2>&1
	if [ "$?" != "0" ]; then
		echo -en "Error. Stopping install.\n"
		exit -1
	else
		echo -en "OK.\n\n"
	fi
}

function do_ruby_install()
{
	echo -en "\nINSTALLING: Chruby and Ruby-Installer\n\n"
	brew install chruby ruby-install git
	echo "source /usr/local/opt/chruby/share/chruby/chruby.sh" >> "${HOME}/.bashrc"
	echo -en "\nINSTALLING: Ruby\n\n"
	ruby-install -r ~/.rubies ruby 2.1
}

function out_done() 
{
	echo -en "\n\nDONE!\n\n" \
		"You will need to restart Terminal before the command will work (in some cases you" \
		"may need to log out and log back in again).\n\n" \
		"To use, simply enter the directory your e-pub is in and type: epub_style_checker.rb\n\n"
}

function main()
{
	out_welcome
	do_check_osx_version
	out_description
	do_install_cli_tools
	do_homebrew_install
	do_homebrew_update
	do_ruby_install
	. /usr/local/opt/chruby/share/chruby/chruby.sh
	chruby 2.1
	gem install bundler
	rm -fr "${INSTALL_DIR_ROOT}/${INSTALL_DIR_ESC}"
	mkdir -p "${INSTALL_DIR_ROOT}"
	cd "${INSTALL_DIR_ROOT}"
	git clone "${GIT_CLONE_PATH}" "${INSTALL_DIR_ROOT}/${INSTALL_DIR_ESC}"
	cd "${INSTALL_DIR_ROOT}/${INSTALL_DIR_ESC}"
	bundle
	chmod u+x "${INSTALL_DIR_ROOT}/${INSTALL_DIR_ESC}/epub_style_checker.rb"
	echo "export PATH=\"${INSTALL_DIR_ROOT}/${INSTALL_DIR_ESC}:$PATH\"" >> "${HOME}/.bashrc"
	out_done
}

main
