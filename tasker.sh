#!/bin/bash

__tasker_WORK_DIR="/tmp/tasker"
rm -rf $__tasker_WORK_DIR
mkdir -p $__tasker_WORK_DIR

__tasker_CURRENT_TASK=""

mkdir $__tasker_WORK_DIR/tasks

function task() {
    mkdir $__tasker_WORK_DIR/tasks/$1
    __tasker_CURRENT_TASK=$1
    unset -f met
    unset -f meet
}

function doc() {
    echo $1 >$__tasker_WORK_DIR/tasks/$__tasker_CURRENT_TASK/doc
}

function depends() {
    echo $* >$__tasker_WORK_DIR/tasks/$__tasker_CURRENT_TASK/depends
}

function endtask() {
    # save 'met' function
    if typeset -F | grep 'declare -f met' >/dev/null; then
        type met | tail +2 >$__tasker_WORK_DIR/tasks/$__tasker_CURRENT_TASK/met
    fi
    # save 'meet' function
    if typeset -F | grep 'declare -f meet' >/dev/null; then
        type meet | tail +2 >$__tasker_WORK_DIR/tasks/$__tasker_CURRENT_TASK/meet
    fi
}

function check_and_do_task() {
    # locals allow recursion
    local doing_task=$1
    local indent=$2
    local task_dir=$__tasker_WORK_DIR/tasks/$doing_task
    # make sure task exists
    if [[ ! -d $task_dir ]]; then
        echo "tasker:$indent Can't find task \"$doing_task\", exiting!"
        exit 1
    fi
    # check if already met
    if [[ -e $task_dir/met ]]; then
        . $task_dir/met
        if met; then
            echo -e "tasker:$indent [\033[0;32m$doing_task\033[0m] Already met, we're done here."
            return
        else
            echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] Not met, checking dependencies..."
        fi
    else
        echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] No met block, checking dependencies..."
    fi
    # not already met, check dependencies
    if [[ -e $task_dir/depends ]]; then
        for task in $(cat $task_dir/depends); do
            check_and_do_task $task "$indent""  |  "
        done
        echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] ...dependencies sorted, doing meet..."
    else
        echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] ...no dependencies, doing meet..."
    fi
    # do meet
    if [[ -f $task_dir/meet ]]; then
        . $task_dir/meet
        meet
        if [[ ( ! -e $task_dir/met ) && $? != 0 ]]; then
            echo -e "tasker:$indent [\033[1;31m$doing_task\033[0m] ...no met block and last command failed, exiting!"
            exit 1
        fi
        echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] ...all done, verifying..."
    else
        echo -e "tasker:$indent [\033[0;33m$doing_task\033[0m] ...no meet, verifying..."
    fi
    # verify meet worked
    if [[ -e $task_dir/met ]]; then
        . $task_dir/met
        if met; then
            echo -e "tasker:$indent [\033[1;32m$doing_task\033[0m] ...satisfied met, nice."
            return
        else
            echo -e "tasker:$indent [\033[1;31m$doing_task\033[0m] ...still not met, exiting!"
            exit 1
        fi
    else
        echo -e "tasker:$indent [\033[1;32m$doing_task\033[0m] ...no met to verify, all done."
    fi
}

function do_action() {
    if (( $# == 0 )); then
    	# echo "tasker: No parameter(s) or default task"
        echo "tasker: No parameter, available tasks are [ $(ls -m $__tasker_WORK_DIR/tasks) ]"
    else
        check_and_do_task $1 ""
    fi
    rm -rf $__tasker_WORK_DIR
}
trap "do_action $*" EXIT
