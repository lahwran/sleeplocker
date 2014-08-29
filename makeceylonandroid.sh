#!/bin/bash


android create project \
    --gradle \
    --gradle-version 0.9.2 \
    --activity MainActivity \
    --package lahwran.androidlocker \
    --target android-19 \
    --path .

# Error: The parameters --activity, --package, --target, --path must be defined for action 'create project'
# 
#        Usage:
#        android [global options] create project [action options]
#        Global options:
#   -s --silent     : Silent mode, shows errors only.
#   -v --verbose    : Verbose mode, shows errors, warnings and all messages.
#      --clear-cache: Clear the SDK Manager repository manifest cache.
#   -h --help       : Help on a specific command.
# 
#                          Action "create project":
#   Creates a new Android project.
# Options:
#   -n --name          : Project name.
#   -a --activity      : Name of the default Activity that is created.
#                        [required]
#   -k --package       : Android package name for the application. [required]
#   -v --gradle-version: Gradle Android plugin version.
#   -t --target        : Target ID of the new project. [required]
#   -g --gradle        : Use gradle template.
#   -p --path          : The new project's directory. [required]
