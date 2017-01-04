#!/bin/bash

# This program and the accompanying materials are made available under the
# terms of the MIT license (X11 license) which accompanies this distribution.

# author: C. Bürger

# BEWARE: This script must be sourced. It expects one variable to be set and sets thirteen variables:
#  in)  profiling_configuration:	Profiling configuration file to parse
#  set) execution_script:		The script to execute for each measurement as defined by the parsed configuration
#  set) parameter_names:		Array of the names of parameters as defined by the parsed configuration
#  set) parameter_descriptions:		Array of parameters descriptions as given by the parsed configuration
#					(one description for each parameter)
#  set) status_names:			Array of the names of measurement statuses
#  set) status_descriptions:		Array of status descriptions
#					(one description for each status)
#  set) result_names:			Array of the names of measurement results as defined by the parsed configuration
#  set) result_descriptions:		Array of measurement result descriptions as given by the parsed configuration
#					(one description for each measurement result)
#  set) criteria_names:			Array of all measurement criteria, i.e, parameter, status and result names
#  set) criteria_descriptions:		Array of criteria descriptions
#					(each description is the one of the respective parameter, status or result)
#  set) number_of_parameters:		Number of parameters defined by the parsed configuration
#  set) number_of_statuses:		Number of measurement statuses
#  set) number_of_results:		Number of measurement results defined by the parsed configuration
#  set) number_of_criteria:		Number of all measurement criteria, i.e., parameters, statuses and results

set -e
set -o pipefail
parse_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z ${profiling_configuration+x} ] || [ ! -f "$profiling_configuration" ]
then
	echo " !!! ERROR: Non-existent or no profiling configuration to parse set !!!" >&2
	exit 2
fi

parsing_mode=execution-script
parameter_names=()
parameter_descriptions=()
status_names=(
	"Date"
	"Status"
)
status_descriptions=(
	"Measurement date (yyyy-mm-dd hh:mm:ss)"
	"Measurement status (failed, aborted, succeeded)"
)
result_names=()
result_descriptions=()

while read line
do
	case $parsing_mode in
	execution-script)
		execution_script="$(
			cd "$( dirname "$profiling_configuration")" &&
			cd "$( dirname "$line")" &&
			pwd )/$( basename "$line" )"
		if [ ! -x "$execution_script" ]
		then
			echo " !!! ERROR: Malformed profiling configuration (non-existent/executable execution script) !!!" >&2
			exit 2
		fi
		parsing_mode=parameters;;
	parameters)
		if [ "$line" == ">" ]
		then
			parsing_mode=results
			continue;
		fi
		IFS='|' read -ra config_line <<< "$line"
		if [ ${#config_line[@]} -ne 2 ]
		then
			echo " !!! ERROR: Malformed profiling configuration (measurement parameter syntax error) !!!" >&2
			exit 2
		fi
		parameter_names+=( "${config_line[0]}" )
		parameter_descriptions+=( "${config_line[1]}" );;
	results)
		IFS='|' read -ra config_line <<< "$line"
		if [ ${#config_line[@]} -ne 2 ]
		then
			echo " !!! ERROR: Malformed profiling configuration (measurement result syntax error) !!!" >&2
			exit 2
		fi
		result_names+=( "${config_line[0]}" )
		result_descriptions+=( "${config_line[1]}" );;
	esac
done < "$profiling_configuration"

criteria_names=(
	"${parameter_names[@]}"
	"${status_names[@]}"
	"${result_names[@]}"
)
criteria_descriptions=(
	"${parameter_descriptions[@]}"
	"${status_descriptions[@]}"
	"${result_descriptions[@]}"
)

if [ -z ${execution_script+x} ]
then
	echo " !!! ERROR: Malformed profiling configuration (missing execution script) !!!" >&2
	exit 2
fi

number_of_parameters=${#parameter_names[@]}
number_of_statuses=${#status_names[@]}
number_of_results=${#result_names[@]}
number_of_criteria=$(( number_of_parameters + number_of_statuses + number_of_results ))
