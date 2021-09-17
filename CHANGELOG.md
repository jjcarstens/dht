# Changelog

## v0.1.2 - 2021-09-16
### Fixes
* Port would crash when trying to read a `[:alias| #Reference<>]` from
  tag produced by a GenServer call

## v0.1.1

* Enhancements
  * Support compiling from Raspbian without requiring `MIX_TARGET`

* Bug Fixes
  * Fix warnings from bad comparisons and definitions

## v0.1.0

Initial release

Ports C for reading sensors. Adds read and telemetry polling API
