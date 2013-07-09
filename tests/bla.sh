#!/bin/bash

bob='--bob-hope'

[[ "${bob}" =~ ^--[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] && echo "rawr"
