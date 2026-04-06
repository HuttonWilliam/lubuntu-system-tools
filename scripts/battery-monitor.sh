#!/bin/bash

# Battery Health Monitor for Lubuntu
# Monitors battery health, charge status, and power usage on laptops
# Usage: ./battery-monitor.sh [--health] [--powersave on|off] [--watch] [--help]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Battery sysfs path (first battery found)
BATTERY_PATH=""

# Function to display help
show_help() {
    cat << EOF
Battery Health Monitor - Monitor battery health and power usage

USAGE:
    ./battery-monitor.sh [OPTIONS]

OPTIONS:
    --health          Show detailed battery health information
    --powersave on    Enable power-saving mode (TLP or cpufreq)
    --powersave off   Disable power-saving mode
    --watch           Monitor battery in real-time (updates every 5 seconds)
    --help            Display this help message

EXAMPLES:
    ./battery-monitor.sh                 # Show current battery status
    ./battery-monitor.sh --health        # Show detailed health info
    ./battery-monitor.sh --powersave on  # Enable power-saving mode
    ./battery-monitor.sh --watch         # Monitor battery in real-time

NOTES:
    - Some readings require root access (sudo) to access power supply data
    - Battery temperature requires a supported sensor or kernel driver
    - Power-saving mode changes may require sudo

EOF
}

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Locate the first battery in sysfs
find_battery() {
    local bat
    for bat in /sys/class/power_supply/BAT*; do
        if [ -d "$bat" ]; then
            BATTERY_PATH="$bat"
            return 0
        fi
    done
    return 1
}

# Read a sysfs value, return empty string if not available
read_sysfs() {
    local file="$1"
    if [ -r "$file" ]; then
        cat "$file" 2>/dev/null || true
    fi
}

# Convert microwatts/microamps to human-readable milliwatts/milliamps
to_milli() {
    local val="$1"
    if [ -n "$val" ] && [ "$val" -gt 0 ] 2>/dev/null; then
        echo $(( val / 1000 ))
    else
        echo "N/A"
    fi
}

# Show current battery status
show_status() {
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Lubuntu Battery Health Monitor     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

    if ! find_battery; then
        print_warning "No battery detected. This system may be a desktop or battery info is unavailable."
        return 0
    fi

    local capacity status charge_now charge_full energy_now energy_full voltage_now current_now power_now

    capacity=$(read_sysfs "$BATTERY_PATH/capacity")
    status=$(read_sysfs "$BATTERY_PATH/status")
    charge_now=$(read_sysfs "$BATTERY_PATH/charge_now")
    charge_full=$(read_sysfs "$BATTERY_PATH/charge_full")
    energy_now=$(read_sysfs "$BATTERY_PATH/energy_now")
    energy_full=$(read_sysfs "$BATTERY_PATH/energy_full")
    voltage_now=$(read_sysfs "$BATTERY_PATH/voltage_now")
    current_now=$(read_sysfs "$BATTERY_PATH/current_now")
    power_now=$(read_sysfs "$BATTERY_PATH/power_now")

    echo ""
    echo -e "${CYAN}── Battery Status ──────────────────────────${NC}"

    # Charge percentage
    if [ -n "$capacity" ]; then
        local bar=""
        local filled=$(( capacity / 10 ))
        local i
        for (( i=0; i<filled; i++ )); do bar+="█"; done
        for (( i=filled; i<10; i++ )); do bar+="░"; done

        if [ "$capacity" -ge 80 ]; then
            echo -e "  Charge:    ${GREEN}${capacity}%${NC}  [${GREEN}${bar}${NC}]"
        elif [ "$capacity" -ge 30 ]; then
            echo -e "  Charge:    ${YELLOW}${capacity}%${NC}  [${YELLOW}${bar}${NC}]"
        else
            echo -e "  Charge:    ${RED}${capacity}%${NC}  [${RED}${bar}${NC}]"
        fi
    else
        echo -e "  Charge:    N/A"
    fi

    # Status (Charging / Discharging / Full / Unknown)
    if [ -n "$status" ]; then
        case "$status" in
            Charging)   echo -e "  Status:    ${GREEN}⚡ Charging${NC}" ;;
            Discharging) echo -e "  Status:    ${YELLOW}🔋 Discharging${NC}" ;;
            Full)        echo -e "  Status:    ${GREEN}✅ Full${NC}" ;;
            *)           echo -e "  Status:    ${BLUE}${status}${NC}" ;;
        esac
    fi

    # Voltage
    if [ -n "$voltage_now" ] && [ "$voltage_now" -gt 0 ] 2>/dev/null; then
        local voltage_mv=$(( voltage_now / 1000 ))
        echo -e "  Voltage:   ${voltage_mv} mV"
    fi

    # Current draw / power
    if [ -n "$power_now" ] && [ "$power_now" -gt 0 ] 2>/dev/null; then
        echo -e "  Power:     $(to_milli "$power_now") mW"
    elif [ -n "$current_now" ] && [ "$current_now" -gt 0 ] 2>/dev/null; then
        echo -e "  Current:   $(to_milli "$current_now") mA"
    fi

    # Time estimate
    estimate_time "$status" "$capacity" "$energy_now" "$energy_full" "$power_now" "$charge_now" "$charge_full" "$current_now"

    echo ""
}

# Estimate time remaining or time to full
estimate_time() {
    local status="$1" capacity="$2" energy_now="$3" energy_full="$4" power_now="$5"
    local charge_now="$6" charge_full="$7" current_now="$8"

    local minutes=""

    if [ "$status" = "Discharging" ]; then
        if [ -n "$energy_now" ] && [ -n "$power_now" ] && [ "$power_now" -gt 0 ] 2>/dev/null; then
            minutes=$(( (energy_now * 60) / power_now ))
        elif [ -n "$charge_now" ] && [ -n "$current_now" ] && [ "$current_now" -gt 0 ] 2>/dev/null; then
            minutes=$(( (charge_now * 60) / current_now ))
        fi
        if [ -n "$minutes" ] && [ "$minutes" -gt 0 ] 2>/dev/null; then
            local h=$(( minutes / 60 ))
            local m=$(( minutes % 60 ))
            echo -e "  Time left: ${CYAN}${h}h ${m}m${NC}"
        fi
    elif [ "$status" = "Charging" ]; then
        if [ -n "$energy_now" ] && [ -n "$energy_full" ] && [ -n "$power_now" ] && [ "$power_now" -gt 0 ] 2>/dev/null; then
            local remaining=$(( energy_full - energy_now ))
            minutes=$(( (remaining * 60) / power_now ))
        elif [ -n "$charge_now" ] && [ -n "$charge_full" ] && [ -n "$current_now" ] && [ "$current_now" -gt 0 ] 2>/dev/null; then
            local remaining=$(( charge_full - charge_now ))
            minutes=$(( (remaining * 60) / current_now ))
        fi
        if [ -n "$minutes" ] && [ "$minutes" -gt 0 ] 2>/dev/null; then
            local h=$(( minutes / 60 ))
            local m=$(( minutes % 60 ))
            echo -e "  Time to full: ${CYAN}${h}h ${m}m${NC}"
        fi
    fi
}

# Show detailed battery health information
show_health() {
    show_status

    if ! find_battery; then
        return 0
    fi

    echo -e "${CYAN}── Battery Health ──────────────────────────${NC}"

    local charge_full charge_full_design energy_full energy_full_design cycle_count manufacturer model_name technology

    charge_full=$(read_sysfs "$BATTERY_PATH/charge_full")
    charge_full_design=$(read_sysfs "$BATTERY_PATH/charge_full_design")
    energy_full=$(read_sysfs "$BATTERY_PATH/energy_full")
    energy_full_design=$(read_sysfs "$BATTERY_PATH/energy_full_design")
    cycle_count=$(read_sysfs "$BATTERY_PATH/cycle_count")
    manufacturer=$(read_sysfs "$BATTERY_PATH/manufacturer")
    model_name=$(read_sysfs "$BATTERY_PATH/model_name")
    technology=$(read_sysfs "$BATTERY_PATH/technology")

    # Calculate health percentage
    local health_pct=""
    if [ -n "$energy_full" ] && [ -n "$energy_full_design" ] && [ "$energy_full_design" -gt 0 ] 2>/dev/null; then
        health_pct=$(( (energy_full * 100) / energy_full_design ))
        echo -e "  Full capacity:    $(to_milli "$energy_full") mWh"
        echo -e "  Design capacity:  $(to_milli "$energy_full_design") mWh"
    elif [ -n "$charge_full" ] && [ -n "$charge_full_design" ] && [ "$charge_full_design" -gt 0 ] 2>/dev/null; then
        health_pct=$(( (charge_full * 100) / charge_full_design ))
        echo -e "  Full capacity:    $(to_milli "$charge_full") mAh"
        echo -e "  Design capacity:  $(to_milli "$charge_full_design") mAh"
    fi

    if [ -n "$health_pct" ]; then
        if [ "$health_pct" -ge 80 ]; then
            echo -e "  Battery health:   ${GREEN}${health_pct}% (Good)${NC}"
        elif [ "$health_pct" -ge 60 ]; then
            echo -e "  Battery health:   ${YELLOW}${health_pct}% (Fair)${NC}"
            print_warning "Battery health is degraded. Consider replacement soon."
        else
            echo -e "  Battery health:   ${RED}${health_pct}% (Poor)${NC}"
            print_warning "Battery health is severely degraded. Replacement recommended."
        fi
    fi

    # Cycle count
    if [ -n "$cycle_count" ] && [ "$cycle_count" != "0" ]; then
        echo -e "  Charge cycles:    ${cycle_count}"
    fi

    # Manufacturer / model
    [ -n "$manufacturer" ] && echo -e "  Manufacturer:     ${manufacturer}"
    [ -n "$model_name" ]   && echo -e "  Model:            ${model_name}"
    [ -n "$technology" ]   && echo -e "  Technology:       ${technology}"

    # Battery temperature via sensors
    echo ""
    echo -e "${CYAN}── Temperature ─────────────────────────────${NC}"
    if command -v sensors &>/dev/null; then
        local temp
        temp=$(sensors 2>/dev/null | grep -i "bat\|acpitz\|temp" | head -n 3 || true)
        if [ -n "$temp" ]; then
            echo "$temp" | while IFS= read -r line; do
                echo -e "  ${line}"
            done
        else
            print_info "No battery temperature sensor found via 'sensors'."
        fi
    else
        print_info "Install 'lm-sensors' for temperature readings: sudo apt install lm-sensors"
    fi

    echo ""
}

# Enable or disable power-saving mode
set_powersave() {
    local mode="$1"

    case "$mode" in
        on)
            echo -e "${YELLOW}Enabling power-saving mode...${NC}"
            if command -v tlp &>/dev/null; then
                sudo tlp bat
                print_status "TLP power-saving mode enabled."
            elif [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                    echo "powersave" | sudo tee "$cpu" > /dev/null
                done
                print_status "CPU governor set to 'powersave'."
            else
                print_warning "Neither TLP nor cpufreq is available. Install TLP for advanced power management:"
                echo "  sudo apt install tlp tlp-rdw"
            fi
            ;;
        off)
            echo -e "${YELLOW}Disabling power-saving mode...${NC}"
            if command -v tlp &>/dev/null; then
                sudo tlp ac
                print_status "TLP switched to AC (performance) mode."
            elif [ -d /sys/devices/system/cpu/cpu0/cpufreq ]; then
                for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                    echo "ondemand" | sudo tee "$cpu" > /dev/null
                done
                print_status "CPU governor set to 'ondemand'."
            else
                print_warning "Neither TLP nor cpufreq is available."
            fi
            ;;
        *)
            print_error "Invalid powersave argument: '$mode'. Use 'on' or 'off'."
            exit 1
            ;;
    esac
}

# Real-time monitoring loop
watch_battery() {
    echo -e "${CYAN}Monitoring battery (Ctrl+C to stop, updates every 5s)...${NC}\n"
    while true; do
        clear
        show_status
        sleep 5
    done
}

# Main script
main() {
    local mode="status"
    local powersave_arg=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --health)
                mode="health"
                shift
                ;;
            --powersave)
                mode="powersave"
                if [[ -n "${2:-}" && "${2}" != --* ]]; then
                    powersave_arg="$2"
                    shift
                else
                    print_error "--powersave requires 'on' or 'off'"
                    exit 1
                fi
                shift
                ;;
            --watch)
                mode="watch"
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    case "$mode" in
        status)   show_status ;;
        health)   show_health ;;
        powersave) set_powersave "$powersave_arg" ;;
        watch)    watch_battery ;;
    esac
}

main "$@"
