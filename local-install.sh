#!/bin/sh

echo "\n\n"
echo "改善"
echo "\n\n"

#echo "+ Uninstalling Gem:"

echo "+ Uninstalling Gem:"
bundle exec gem uninstall kaizen

echo "+ Building Gemspec"
bundle exec rake build

echo "+ Installing Gem"
bundle exec rake install
