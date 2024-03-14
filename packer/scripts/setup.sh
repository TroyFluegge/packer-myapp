#!/bin/bash

echo 'debconf debconf/frontend select Noninteractive' | sudo debconf-set-selections
sudo apt-get install -y -q
sudo apt-get update
sudo apt-get -y upgrade

## Add OS hardening configurations, security agents, 
# and other base image settings here.
