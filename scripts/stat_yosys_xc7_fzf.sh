#!/bin/bash

BASE_DIR=$(dirname $(cd "$(dirname "$0")" && pwd))
BUILD_DIR=$BASE_DIR/build

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
GRAY='\033[1;37m'
NC='\033[0m' 
BOLD='\033[1m'
DIM='\033[2m'

show_header() {
  echo -e "${BLUE}"
  echo "            ███████╗████████╗ █████╗ ████████╗"
  echo "            ██╔════╝╚══██╔══╝██╔══██╗╚══██╔══╝"
  echo "            ███████╗   ██║   ███████║   ██║   "
  echo "            ╚════██║   ██║   ██╔══██║   ██║   "
  echo "            ███████║   ██║   ██║  ██║   ██║   "
  echo "            ╚══════╝   ╚═╝   ╚═╝  ╚═╝   ╚═╝   "
  echo -e "${NC}"
  echo -e "${DIM}Stat Automation Tool${NC}"
  echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
  echo
}

show_status() {
  local status=$1
  local message=$2
  
  case $status in
    "info") echo -e "${DIM}│  ${message}${NC}" >&2;;
    "success") echo -e "${GREEN}✔  ${message}${NC}" >&2;;
    "warning") echo -e "${YELLOW}│  ${message}${NC}" >&2;;
    "error") echo -e "${RED}✖  ${message}${NC}" >&2;;
    *) echo -e "${DIM}│  ${message}${NC}" >&2;;
  esac
}

select_module() {
  echo -e "${DIM}◇ Select a module: ${NC}" >&2
  local module_file=$(find "$BUILD_DIR" -type f \( -name "*.sv" -o -name "*.v" \) | fzf --height=30% --prompt="Fuzzy Search: " --header="Use arrow keys to navigate, Enter to select")
  
  if [ -z "$module_file" ]; then
    echo -e "${RED}✖  No testbench selected. Skip.${NC}" >&2
    exit 1
  fi
  
  echo -e "\033[1A\033[2K${GREEN}◆ Selected: $(basename "$module_file")${NC} ($module_file)" >&2

  echo $(basename $module_file)
}

fetch_top_module() {
  local flag=0 
  echo -ne "${DIM}│  Enter the top module name: ${NC}" >&2

  read -r top_module
  while [[ -z "$top_module" ]]; do
    echo -ne "\033[1A\033[2K" >&2
    show_status "warning" "Top module name cannot be empty!"
    read -r top_module
    flag=1
  done

  if [[ $flag -eq 1 ]]; then
    echo -ne "\033[1A\033[2K" >&2
  fi
  show_status "success" "Top module name set to: $top_module"

  echo "$top_module"
}

run_stat() {
  show_header
  module_file="$(select_module)"
  top_module="$(fetch_top_module)"
  LOG_DIR="$BASE_DIR/sims/logs/${top_module%.*}"
  mkdir -p "$LOG_DIR"

  cd "$BUILD_DIR" || exit 1
  show_status "info" "Generating .ys file: $module_file..."
  cat > "synth_${top_module}.ys" << EOF

read_verilog -sv ${module_file}
hierarchy -check -top ${top_module}

synth_xilinx -family xc7 -top ${top_module}

write_verilog synth_${top_module}.v
show

EOF
  show_status "info" "Running Yosys synthesis and stat..."
  yosys "synth_${top_module}.ys" > "$LOG_DIR/stat.log" 2>&1
  show_status "success" "Stat run completed. Logs saved in $LOG_DIR"
}

# Main execution
run_stat
