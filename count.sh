#!/bin/bash

cat $@ | grep -v '^$' | grep -v '^;' | wc -l
