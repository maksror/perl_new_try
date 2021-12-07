#!/usr/bin/perl

use Modern::Perl;

use lib "./";
use RequestHandlers;

RequestHandlers::app->start;