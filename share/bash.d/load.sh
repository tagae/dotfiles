#!/bin/sh

load () {
    test -r "$1" && source "$1"
}
