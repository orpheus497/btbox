#!/bin/sh
##Script function and purpose: UI Utility functions for the btbox project, providing standardized colors and messaging styles.

# Color definitions
# Use ANSI escape codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

##Function purpose: Display the btbox ASCII banner.
show_banner() {
    printf "%s%s" "${CYAN}" "${BOLD}"
    printf "  _      _   _                \n"
    printf " | |    | | | |               \n"
    printf " | |__  | |_| |__   _____  __ \n"
    printf " | '_ \\ | __| '_ \\ / _ \\ \\/ / \n"
    printf " | |_) || |_| |_) | (_) >  <  \n"
    printf " |_.__/  \\__|_.__/ \\___/_/\\_\\ \n"
    printf "                              \n"
    printf "   Bluetooth Devices for FreeBSD \n"
    printf "%s\n" "${NC}"
}

##Function purpose: Print an informational message.
msg_info() {
    printf "${BLUE}===>${NC} %s\n" "$1"
}

##Function purpose: Print a success message.
msg_ok() {
    printf "${GREEN}[ OK ]${NC} %s\n" "$1"
}

##Function purpose: Print an error message.
msg_err() {
    printf "${RED}[ ERR ]${NC} %s\n" "$1" >&2
}

##Function purpose: Print a warning message.
msg_warn() {
    printf "${YELLOW}[ !! ]${NC} %s\n" "$1"
}

##Function purpose: Print a status line.
msg_status() {
    printf "${MAGENTA}STATUS:${NC} %s\n" "$1"
}
