#!/bin/zsh

THIS_DIR=$(cd "$(dirname "{BASH_SOURCE[0]}" )" && pwd)

export BMV2_PATH=~/P4/behavioral-model
SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch

CLI_PATH=$BMV2_PATH/tools/runtime_CLI.py

p4c-bm2-ss --arch v1model -o output.json \
		--p4runtime-file my_app.p4info \
		--p4runtime-format text \
		my_app.p4

export PYTHONPATH=~/P4/behavioral-model/mininet
sudo $SWITCH_PATH >/dev/null 2>&1
sudo PYTHONPATH=$PYTHONPATH:~/P4/behavioral-model/mininet/ python2 topo.py \
	--behavioral_exe simple_switch \
	--json output.json \
	--cli $CLI_PATH
