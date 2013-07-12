#!/bin/bash

# Copyright 2013 Kyle Harper
# Licensed per the details in the LICENSE file in this package.

git log --pretty=format:'%H%n  Author: %cn%n  Date: %ci%n  Comment: %s%n%n' --graph > ../CHANGELOG
