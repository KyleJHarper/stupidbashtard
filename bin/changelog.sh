#!/bin/bash

git log --pretty=format:'%H%n  Author: %cn%n  Date: %ci%n  Comment: %s%n%n' --graph > ../CHANGELOG
