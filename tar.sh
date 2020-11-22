#!/bin/bash

sid=$(grep -w sid user/sid.h | cut -d' ' -f3)
curdir=$(pwd | awk -F / '{print $NF}')
make clean > /dev/null;
rm -f $sid.tar;
cd ..;
tar cf $sid.tar --exclude .vscode --exclude .git $curdir 
mv $sid.tar $curdir/

