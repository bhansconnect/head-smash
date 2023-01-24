#!/bin/bash

cd $(dirname $0)

butler push linux bren077s/head-smash:linux
butler push mac bren077s/head-smash:mac
butler push windows bren077s/head-smash:windows
butler push web bren077s/head-smash:web

