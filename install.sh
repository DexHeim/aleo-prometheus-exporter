#!/bin/bash

# things to do:
# check if config exist before cleaning up /etc/xinet.d folder
# wget condition doesn't work for xinet.d content, need to fix

# '$EXPORTER_END_POINT' for serving metrics. We will use this variable here only to check if installation complete successfully.
# Default port in repository is 9101, if this does not fit, edit '/etc/xinet.d/aleo-exporter' and change 'port = 9100' according setup requirements.
# If port is busy for whatever reason, endpoint will not be up and curl shows nothing.

EXPORTER_END_POINT="127.0.0.1:9200"

# node RPC ( default 3032 )
NODE_RPC="http://127.0.0.1:3032"

if [ "$EUID" -ne 0 ]; then
    echo && echo " Please run as root !" && echo
    exit
fi

function CheckRPC() {

    re='^[0-9]+$'

    echo && echo " RPC Check !" && echo

    rpc_status=$(curl -s --data-binary '{"jsonrpc": "2.0", "id":"documentation", "method": "latestblock" }' \
        -H 'content-type: application/json' "http://127.0.0.1:3032" |
        jq -r .result)
        
    echo $rpc_status
    echo $re

    if ! [[ "$rpc_status" =~ $re ]]; then
        echo " Can't get valid response from RPC, or node is dead or RPC is on another port number." && echo
        #exit
    else
        echo " RPC response with current node heigh: $rpc_status"
    fi

}

function InstallPackage() {

    pkg="$1"

    echo && echo " Checking for package: $pkg" && echo

    status="$(dpkg-query -W --showformat='${db:Status-Status}' $pkg 2>&1)"

    if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
        echo " Installing $pkg ..." && echo
        apt-get --yes install "$pkg"
    else
        echo " $pkg installed"
    fi

}

InstallPackage xinetd
InstallPackage jq

CheckRPC

if [ -d "/etc/xinetd.d" ]; then
    echo && echo " Xinetd configuration folder exist, good." && echo
else
    echo " Where is no path /etc/xinetd.d, possible xinetd installation failed, or unknown Linux distribution."
    exit 1
fi

# download xinetd service configuration
if ! [ -f "/etc/xinetd.d/aleo-exporter" ]; then
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/aleo-exporter.conf -q --show-progress --progress=bar:force -P /etc/xinetd.d/ 2>&1
    sudo mv /etc/xinetd.d/aleo-exporter.conf /etc/xinetd.d/aleo-exporter
else
    echo "Updating /etc/xinetd.d/aleo-exporter..."
    rm /etc/xinetd.d/aleo-exporter
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/aleo-exporter.conf -q --show-progress --progress=bar:force -P /etc/xinetd.d/ 2>&1
    sudo mv /etc/xinetd.d/aleo-exporter.conf /etc/xinetd.d/aleo-exporter
fi

# download exporter
if ! [ -f "/opt/metrics.d/aleo-exporter" ]; then
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/aleo-exporter -q --show-progress --progress=bar:force -P /opt/metrics.d/ 2>&1
else
    echo "Updating /opt/metrics.d/aleo-exporter..."
    rm /opt/metrics.d/aleo-exporter
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/aleo-exporter -q --show-progress --progress=bar:force -P /opt/metrics.d/ 2>&1
fi

# download http wrapper
if ! [ -f "/opt/metrics.d/httpwrapper" ]; then
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/httpwrapper -q --show-progress --progress=bar:force -P /opt/metrics.d/ 2>&1
else
    echo "Updating /opt/metrics.d/httpwrapper..."
    rm /opt/metrics.d/httpwrapper
    sudo wget --no-check-certificate https://raw.githubusercontent.com/DexHeim/aleo-prometheus-exporter/main/httpwrapper -q --show-progress --progress=bar:force -P /opt/metrics.d/ 2>&1
fi

echo

# make staff exicutable
chmod +x /opt/metrics.d/httpwrapper
chmod +x /opt/metrics.d/aleo-exporter

# create temporaty collector and log file
touch /opt/metrics.d/log_exporter.log
touch /opt/metrics.d/aleo.metrics

# restart xinetd
echo " Restarting xinetd server, applying configuration ..."
systemctl restart xinetd && sleep 5
journalctl -u xinetd -f -n 10 && echo

# check if endpoint is ready
echo " End point test:" && echo
curl -s "$EXPORTER_END_POINT" | grep -e "aleo_nodeinfo_is" -e "aleo_node_currently_connected_peers" | grep -v 'HELP' | grep -v 'TYPE' && echo
