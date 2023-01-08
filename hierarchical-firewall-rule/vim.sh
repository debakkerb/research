#!/usr/bin/env bash

printf '%s\n' *.tf > .filenames

vi `cat .filenames`
