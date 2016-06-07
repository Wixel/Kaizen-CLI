#!/bin/sh

echo "+ Uninstalling Gem:"
gem uninstall kaizen

echo "+ Building Gemspec"
rake build --trace

echo "+ Installing Gem"
rake install --trace
