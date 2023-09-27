#! /usr/bin/env bash

MS_IMPORT_PATH=$( miniscript -c 'print env.MS_IMPORT_PATH' ):.  miniscript startup.ms $@

