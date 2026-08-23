#!/bin/sh

rm -f robots.txt
wget https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.txt
grep User-agent robots.txt | awk ' BEGIN { ORS="|" } { print $2 }' > badbots.txt

# rm -f robots.json
# wget https://raw.githubusercontent.com/ai-robots-txt/ai.robots.txt/refs/heads/main/robots.json
