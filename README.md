# tasker
'tasker' is a simple build tool which uses a native bash DSL. It is perfect for small Java projects when you can't be bothered setting up Maven, small c/c++ projects when you don't want to brush up on makefiles (again).

## Elements of a 'tasker' script
**`task`** block (required) defines a task
```bash
task build_it
    ...
endtask
```

**`doc`** section (not required) - adds a short description of the task,
```bash
task build_it
    doc "Task to build the thing"
endtask
```

**`depends`** section (not required) - lists tasks to be done before this one,
```bash
task build_it
    depends clean_up generate_files
endtask
```

**`met`** block (not required) - test if this task needs to be run, and that the execution was successful after running. The following example checks if the build directory already exists before trying to create it. A task will fail if the 'met' block doesn't pass after executing the 'meet' block. The statements can be on multiple lines, the return value from the last statement determines if the task has been met or not (but the extra semicolon is required if it's all on one line).
```bash
task make_build_directory
    met() { test -d build; }
    ...
endtask
```

**`meet`** block (not required) - contains commands to complete the task
```bash
task make_build_directory
    meet() {
        mkdir build
    }
endtask
```

## Example
In the following example;
- The **`run-and-clean`** task just requires that the tasks **`run`** and **`clean`** are executed.
- The **`build`** task creates an executable shell script. It only runs if an executable script named 'message.sh' doesn't already exist. It also verifies that the script exists after running.
- The **`run`** task requires that the **`build`** task has run, then runs the 'message.sh' shell script.
- The **`cleanup`** task deletes 'message.sh' if it hasn't already been deleted, then checks that it has gone afterwards.

```bash
. tasker.sh

task run-and-clean
    doc "Task to build and run 'hello'"
    depends run clean
endtask

task build
    doc "Create shell script"
    met() { test -x message.sh; }
    meet() {
        echo "#!/bin/bash" > message.sh
        echo "echo Hello" >> message.sh
        chmod +x message.sh
    }
endtask

task run
    doc "Run the shell script"
    depends build
    meet() {
        ./message.sh
    }
endtask

task clean
    doc "Cleanup"
    met() { test ! -f message.sh; }
    meet() {
        rm message.sh
    }
endtask
```

The output looks like this,

```
Johns-Mac:tasker jdoxey$ ./example.sh run-and-clean
tasker: [run-and-clean] No met block, checking dependencies...
tasker:  |   [run] No met block, checking dependencies...
tasker:  |    |   [build] Not met, checking dependencies...
tasker:  |    |   [build] ...no dependencies, doing meet...
tasker:  |    |   [build] ...all done, verifying...
tasker:  |    |   [build] ...satisfied met, nice.
tasker:  |   [run] ...dependencies sorted, doing meet...
Hello
tasker:  |   [run] ...all done, verifying...
tasker:  |   [run] ...no met to verify, all done.
tasker:  |   [clean] Not met, checking dependencies...
tasker:  |   [clean] ...no dependencies, doing meet...
tasker:  |   [clean] ...all done, verifying...
tasker:  |   [clean] ...satisfied met, nice.
tasker: [run-and-clean] ...dependencies sorted, doing meet...
tasker: [run-and-clean] ...no meet, verifying...
tasker: [run-and-clean] ...no met to verify, all done.
```

## Bash cheat sheet
Bash can be a bit strange, below are some notes which help me remember the weird bits.
- You can test values in bash with,
  - **`test`** - check for files, compare strings, (and some awkward integer comparisons). For example `test -x script.sh` checks that an executable file called "script.sh" exists. Check `man test` for details.
  - **`[ expression ]`** - single square bracket expressions are the same as using the 'test' command. E.g. `test -f file.txt` is the same as `[ -f file.txt ]`. (I usually find `test ...` more readable than this shorthand).
  - **`[[ expression ]]`** - double square brackets are a bash built-in. They are similar to `test` and single square brackets except you can also do regex matching with '=~', and you can combine expressions with `&&` and `||`. For documentation, see 'man bash' and search for '[[ expression ]]'. 
  - **`((expression))`** - double round brackets are for arithmetic (numeric) expressions. Check `man bash` and look for the `ARITHMETIC EVALUATION` section.
  - **`(commands)`** - commands in single round brackets are executed in a sub-shell, they are NOT usually used for testing conditions.
- In bash, a `0` return value is a SUCCESS, any non-zero value is an ERROR. One mnemonic goes, "In bash there is one way to succeed, and many ways to fail".

## ToDo
- [ ] Print 'doc' descriptions when you type 'help' (or '-h' or '--help' or '-help')
- [ ] Be able to designate a 'default' task (chosen if you don't specify a target)
- [ ] Dial down logging (with option to turn it back up)
