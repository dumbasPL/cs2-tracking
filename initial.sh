#!/bin/bash

# loop over lines in depots.txt
while read -r line; do
  /run.sh "$line"
done < depots.txt