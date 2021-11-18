#!/usr/bin/perl

use lib "./";
use Mojolicious::Lite -signatures;
use mysql_operations qw (show_all search add_contact remove_contact modify_contact);

use strict;
use warnings;

get '/' => sub ($c) {
    my @rows = show_all ();
    $c->stash( 'len'=>$#rows );
    $c->render( template => 'index', 
                rows => \@rows, );
};

post '/' => sub ($c) {
    my $result = add_contact( $c->param ('name'), 
                              $c->param ('phone'),
                            );
    if ( $result eq 0 ) {
        $c->redirect_to( '/' );
    } 
    else {
        $c->stash( error => $result );
        $c->render( template => 'alert' );
    }
};

post '/search' => sub ($c) {
    my $pattern = $c->param( 'data' );
    my @rows = search( $pattern );
    
    $c->stash( 'len'=>$#rows );
    $c->render( template => 'index', 
                rows => \@rows, );
};

app->start;
