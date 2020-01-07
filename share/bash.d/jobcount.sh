#!/bin/sh

jobcount () {
    jobs | wc -l | tr -d " "
}
