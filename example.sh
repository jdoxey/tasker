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
