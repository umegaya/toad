#!/bin/bash

export AWS_ACCESS_KEY=%ACCESS_KEY%
export AWS_SECRET_KEY=%SECRET_KEY%

cd /home/%USER%/server/
yue main.lua

