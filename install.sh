#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# The visible panel account can be initialized from environment variables.
# Supported names:
#   XUI_ADMIN_USER / XUI_USERNAME
#   XUI_ADMIN_PASS / XUI_PASSWORD
#   XUI_ADMIN_PORT / XUI_PORT

[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error:${plain} please run this script as root.\n" && exit 1

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to detect the server operating system." >&2
    exit 1
fi

echo "Current operating system: $release"

arch() {
    case "$(uname -m)" in
        x86_64 | x64 | amd64 ) echo 'amd64' ;;
        i*86 | x86 ) echo '386' ;;
        armv8* | armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        armv7* | armv7 | arm ) echo 'armv7' ;;
        armv6* | armv6 ) echo 'armv6' ;;
        armv5* | armv5 ) echo 'armv5' ;;
        s390x ) echo 's390x' ;;
        *) echo -e "${red}Unsupported CPU architecture.${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "Architecture: $(arch)"

os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "arch" ]]; then
    echo "Detected Arch Linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Detected Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Detected Armbian"
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use CentOS 8 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red}Please use Ubuntu 20 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red}Please use Fedora 36 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red}Please use Debian 11 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red}Please use AlmaLinux 9 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red}Please use RockyLinux 9 or newer.${plain}\n" && exit 1
    fi
elif [[ "${release}" == "oracle" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Oracle Linux 8 or newer.${plain}\n" && exit 1
    fi
else
    echo -e "${red}This script does not support your operating system.${plain}\n"
    echo "Supported systems:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 9+"
    echo "- Rocky Linux 9+"
    echo "- Oracle Linux 8+"
    exit 1
fi

install_base() {
    case "${release}" in
    centos | almalinux | rocky | oracle)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

resolve_admin_settings() {
    config_account="${XUI_ADMIN_USER:-${XUI_USERNAME}}"
    config_password="${XUI_ADMIN_PASS:-${XUI_PASSWORD}}"
    config_port="${XUI_ADMIN_PORT:-${XUI_PORT}}"
}

config_after_install() {
    resolve_admin_settings

    if [[ -n "${config_account}" && -n "${config_password}" ]]; then
        echo -e "${yellow}Applying visible panel account from environment variables...${plain}"
        /usr/local/x-ui/x-ui setting -username "${config_account}" -password "${config_password}"
        echo -e "${green}Panel username updated: ${config_account}${plain}"
        if [[ -n "${config_port}" ]]; then
            /usr/local/x-ui/x-ui setting -port "${config_port}"
            echo -e "${green}Panel port updated: ${config_port}${plain}"
        else
            echo -e "${yellow}Panel port was not provided, keeping the current/default port.${plain}"
        fi
        /usr/local/x-ui/x-ui migrate
        return
    fi

    echo -e "${yellow}Install/update finished. For panel safety, please set a visible admin account.${plain}"
    read -p "Continue with custom settings [y/n]? " config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        read -p "Set panel username: " config_account
        echo -e "${yellow}Panel username will be: ${config_account}${plain}"
        read -p "Set panel password: " config_password
        echo -e "${yellow}Panel password has been captured.${plain}"
        read -p "Set panel port: " config_port
        echo -e "${yellow}Panel port will be: ${config_port}${plain}"
        echo -e "${yellow}Initializing, please wait...${plain}"
        /usr/local/x-ui/x-ui setting -username "${config_account}" -password "${config_password}"
        echo -e "${yellow}Panel username and password updated successfully.${plain}"
        /usr/local/x-ui/x-ui setting -port "${config_port}"
        echo -e "${yellow}Panel port updated successfully.${plain}"
    else
        echo -e "${red}Cancelled.${plain}"
        if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
            local usernameTemp
            local passwordTemp
            usernameTemp=$(head -c 6 /dev/urandom | base64)
            passwordTemp=$(head -c 6 /dev/urandom | base64)
            /usr/local/x-ui/x-ui setting -username "${usernameTemp}" -password "${passwordTemp}"
            echo -e "Fresh install detected. A random visible login has been generated:"
            echo -e "###############################################"
            echo -e "${green}Username: ${usernameTemp}${plain}"
            echo -e "${green}Password: ${passwordTemp}${plain}"
            echo -e "###############################################"
            echo -e "${red}If you forget the login, run x-ui and choose option 8 after installation.${plain}"
        else
            echo -e "${red}Upgrade detected. Existing settings are preserved. If you forgot the login, run x-ui and choose option 8.${plain}"
        fi
    fi
    /usr/local/x-ui/x-ui migrate
}

install_x_ui() {
    cd /usr/local/ || exit 1

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/Misaka-blog/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ -z "$last_version" ]]; then
            echo -e "${red}Failed to fetch the latest x-ui version. GitHub API may be rate-limited.${plain}"
            exit 1
        fi
        echo -e "Latest x-ui version detected: ${last_version}. Starting install..."
        wget -N --no-check-certificate -O "/usr/local/x-ui-linux-$(arch).tar.gz" "https://github.com/Misaka-blog/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch).tar.gz"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download x-ui. Please verify the server can access GitHub.${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/Misaka-blog/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "Installing x-ui ${last_version}..."
        wget -N --no-check-certificate -O "/usr/local/x-ui-linux-$(arch).tar.gz" "${url}"
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Failed to download x-ui ${last_version}. Please verify that version exists.${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf "x-ui-linux-$(arch).tar.gz"
    rm -f "x-ui-linux-$(arch).tar.gz"
    cd x-ui || exit 1
    chmod +x x-ui

    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv "bin/xray-linux-$(arch)" bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui "bin/xray-linux-$(arch)"
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/Misaka-blog/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui

    systemctl stop warp-go >/dev/null 2>&1
    wg-quick down wgcf >/dev/null 2>&1
    ipv4=$(curl -s4m8 ip.p3terx.com -k | sed -n 1p)
    ipv6=$(curl -s6m8 ip.p3terx.com -k | sed -n 1p)
    systemctl start warp-go >/dev/null 2>&1
    wg-quick up wgcf >/dev/null 2>&1

    echo -e "${green}x-ui ${last_version}${plain} installed successfully and is starting..."
    echo ""
    echo "x-ui control commands:"
    echo "-------------------------------------------------"
    echo "x-ui              - open management script"
    echo "x-ui start        - start x-ui"
    echo "x-ui stop         - stop x-ui"
    echo "x-ui restart      - restart x-ui"
    echo "x-ui status       - show x-ui status"
    echo "x-ui enable       - enable autostart"
    echo "x-ui disable      - disable autostart"
    echo "x-ui log          - show x-ui logs"
    echo "x-ui banlog       - show Fail2ban logs"
    echo "x-ui update       - update x-ui"
    echo "x-ui install      - install x-ui"
    echo "x-ui uninstall    - uninstall x-ui"
    echo "-------------------------------------------------"
    echo ""
    if [[ -n $ipv4 && -n $config_port ]]; then
        echo -e "${yellow}Panel IPv4 URL:${plain} ${green}http://${ipv4}:${config_port}${plain}"
    fi
    if [[ -n $ipv6 && -n $config_port ]]; then
        echo -e "${yellow}Panel IPv6 URL:${plain} ${green}http://[${ipv6}]:${config_port}${plain}"
    fi
    if [[ -z $config_port ]]; then
        echo -e "${yellow}Panel port was not captured by this run. Check the active port with x-ui if needed.${plain}"
    else
        echo -e "Make sure port ${red}${config_port}${plain} is not in use by another program and is allowed by the firewall."
    fi
}

install_base
install_x_ui "$1"
