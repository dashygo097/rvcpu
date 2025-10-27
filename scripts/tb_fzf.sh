#!/bin/bash

BASE_DIR=$(dirname $(cd "$(dirname "$0")" && pwd))
TB_DIR=$BASE_DIR/sims/tb

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
  echo "  ████████╗███████╗███████╗████████╗██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗"
  echo "  ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║"
  echo "     ██║   █████╗  ███████╗   ██║   ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║"
  echo "     ██║   ██╔══╝  ╚════██║   ██║   ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║"
  echo "     ██║   ███████╗███████║   ██║   ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║"
  echo "     ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝"
  echo -e "${NC}"
  echo -e "${DIM}                Testbench Automation Tool${NC}"
  echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
  echo
}

show_status() {
  local status=$1
  local message=$2
  
  case $status in
    "info") echo -e "${DIM}│  ${message}${NC}" ;;
    "success") echo -e "${GREEN}✔  ${message}${NC}" ;;
    "warning") echo -e "${YELLOW}⚠  ${message}${NC}" ;;
    "error") echo -e "${RED}✖  ${message}${NC}" ;;
    *) echo -e "${DIM}│  ${message}${NC}" ;;
  esac
}

select_testbench() {
  echo -e "${DIM}◇ Select a testbench: ${NC}" >&2
local tb_file=$(find "$TB_DIR" -type f \( -name "*.sv" -o -name "*.v" \) | sed "s|^$TB_DIR/||" | fzf --height=30% --prompt="Fuzzy Search: " --header="Use arrow keys to navigate, Enter to select")
  
  if [ -z "$tb_file" ]; then
    echo -e "${RED}✖  No testbench selected. Skip.${NC}" >&2
    exit 1
  fi
  
  echo -e "\033[1A\033[2K${GREEN}◆ Selected: $(basename "$tb_file")${NC} ($tb_file)" >&2

  echo $(basename $tb_file)
}

select_vcd() {
  echo -e "${DIM}◇ Select a VCD file: ${TB_DIR}/obj_dir${NC}" >&2
  local vcd_file=$(find "$TB_DIR/obj_dir" -type f -name "*.vcd" | sed "s|^$TB_DIR/obj_dir||" | fzf --height=40% --prompt="Fuzzy Search: " --header="Use arrow keys to navigate, Enter to select")

  if [ -z "$vcd_file" ]; then
    exit 1
  fi

  echo -e "\033[1A\033[2K${GREEN}◆ Selected: $(basename "$vcd_file")${NC} ($vcd_file)" >&2

  echo $(basename $vcd_file)
}

select_wave_viewer() {
    local wave_viewer=""
    local options=("Surfer" "GTKWave" "Custom")
    local current_selection=0
    
    echo -e "${DIM}${BLUE}◇ Select WaveViewer ${NC}" >&2
    echo -e "│${DIM} Use arrow keys to navigate, Enter to confirm${NC}" >&2
    
    local menu_lines=0
    
    display_menu() {
        for i in "${!options[@]}"; do
            if [ $i -eq "$current_selection" ]; then
                echo -e "│ ${BOLD}${GREEN}❯ ${options[i]}${NC}${SPACE}" >&2
            else
                echo -e "│ ${DIM}${GRAY}${options[i]}${NC}${SPACE}" >&2
            fi
        done
        menu_lines="${#options[@]}"
    }
    
    display_menu
    
    echo -ne "\033[s" >&2
    
    while true; do
        read -rsn1 key
        
        if [ "$key" = $'\x1b' ]; then
            read -rsn1 -t 1 key2
            if [ "$key2" = '[' ]; then
                read -rsn1 key3
                case "$key3" in
                    'A')
                        if [ "$current_selection" -gt 0 ]; then
                            current_selection="$((current_selection - 1))"
                            echo -ne "\033[u" >&2
                            echo -ne "\033[${menu_lines}A\033[J" >&2
                            display_menu
                        fi
                        ;;
                    'B') 
                        if [ "$current_selection" -lt "$((${#options[@]} - 1))" ]; then
                            current_selection="$((current_selection + 1))"
                            echo -ne "\033[u" >&2
                            echo -ne "\033[${menu_lines}A\033[J" >&2
                            display_menu
                        fi
                        ;;
                esac
            fi
        elif [ "$key" = "" ]; then
            break
        fi
    done
    
    echo -ne "\033[u\033[J" >&2 
    
    case "${options[current_selection]}" in
        "None") 
            wave_viewer=""
            ;;
        "Custom")
            echo -n "Please enter a custom wave viewer command: " >&2
            read custom_bt
            wave_viewer="${custom_bt}"
            echo -ne "\033[A\033[2K" >&2
            ;;
        *)
            wave_viewer="${options[current_selection]}"
            ;;
    esac
    
    echo -e "${DIM}${BLUE}◆ Wave Viewer Selected!${NC}${SPACE}" >&2
    display_menu
    echo -e "\033[3A\033[3K${GREEN}✔ Wave Viewer: ${NC}${BOLD}$wave_viewer${NC}" >&2
    
    echo "$wave_viewer"
}
 

run_test() {
  show_header
  tb_file="$(select_testbench)"
  LOG_DIR="$BASE_DIR/sims/logs/${tb_file%.*}"
  mkdir -p "$LOG_DIR"

  show_status "info" "Compile with Verilator: $tb_file"
  cd "$TB_DIR" || exit
  verilator --quiet --cc --exe --build --binary --trace -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC "$tb_file" -o "${tb_file%.*}" > "$LOG_DIR/tb.log" 2>&1
  show_status "success" "Compilation completed. Logs saved in $LOG_DIR"
  cd "$TB_DIR/obj_dir" || exit
  "./${tb_file%.*}" > "$LOG_DIR/simulation_run.log" 2>&1 

  show_status "info" "Using waveform viewer: gtkwave"
  vcd_file="$(select_vcd)"
  if [ -z "$vcd_file" ]; then
    show_status "error" "VCD not selected. Exiting."
    exit 1
  fi

  show_status "info" "Select Waveform Viewer:"
  wave_viewer="$(select_wave_viewer)"
  eval "$wave_viewer $vcd_file" > "$LOG_DIR/${wave_viewer}.log" 2>&1
  echo -n " "

  show_status "success" "Testbench run completed. Logs saved in $LOG_DIR"
}

# Main execution
run_test
