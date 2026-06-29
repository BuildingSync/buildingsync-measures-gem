# Buildingsync Measures Gem

This repository contains measures used in the BuildingSync to OpenStudio Simulator ([BOSS](https://github.com/BuildingSync/BOSS)) workflow.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'buildingsync-measures'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install 'buildingsync-measures'

## Usage

To be filled out later. 

## TODO

- [ ] Remove measures from OpenStudio-Measures to standardize on this location
- [ ] Update measures to code standards
- [ ] Review and fill out the gemspec file with author and gem description

# Releasing

* Update change log
* Update version in `/lib/openstudio/buildingsync-measures/version.rb`
* Merge down to master
* Release via github
* run `rake release` from master
