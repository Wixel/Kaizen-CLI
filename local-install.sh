#!/bin/sh

echo "+ Uninstalling Gem:"
gem uninstall kaizen

echo "+ Building Gemspec"
rake build

echo "+ Installing Gem"
rake install
