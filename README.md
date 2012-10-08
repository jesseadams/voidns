## VoidNS ##

Uses the Linode API to update DNS resources with a new IP address. This is useful for keeping A records in sync in case IP addresses change. This is similar to how dyndns and no-ip clients work.

#### Requirements ####

* Ruby 1.8.7 or 1.9.3

#### Installation ####

1. Git clone
2. cp config.yml.example to config.yml and fill it out
3. [sudo] gem install linode

#### Usage ####

`ruby update.rb`

#### IP Address Lookup ####

If you leave the external_interface field blank in config.yml then the script will simply attempt a `curl icanhazip.com`. Otherwise, it will attempt to run *nix-y commands and parse the output of the command. It checks to see if a command exists prior to attempting to run it. If no known command exists then it simply aborts. The command order is `ifconfig` -> `ip addr show`.

#### Credits ####

* @rick and the [linode ruby gem](https://github.com/rick/linode)
* Linode and their [wonderful API](http://www.linode.com/api/)

#### License ####

GPLv3
