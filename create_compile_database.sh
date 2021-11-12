#!/bin/bash

# you need to install bear in order to create the compile database
# this will override the existing compiler_commands.json
# you have to run make clean before executing bear, otherwise it will be incomplete
make clean
bear -- make VERSION=eu
