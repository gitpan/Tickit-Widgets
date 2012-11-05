#!/usr/bin/perl

use strict;

use Test::More tests => 9;

use Tickit::Test;

use Tickit::Widget::Button;

my $root = mk_window;

my $win = $root->make_sub( 0, 0, 3, 15 );

my $clicked = 0;
my $button = Tickit::Widget::Button->new(
   label => "Click me",
   on_click => sub { $clicked++ },
);

ok( defined $button, 'defined $button' );

is( $button->label, "Click me", '$button->label' );
is( $button->align,  0.5,       '$button->align' );
is( $button->valign, 0.5,       '$button->valign' );

$button->set_window( $win );

flush_tickit;

is_display( [ [TEXT("+-------------+")],
              [TEXT("|  Click me   |")],
              [TEXT("+-------------+")] ],
            'Display initially' );

pressmouse( press => 1, 1, 10 );

flush_tickit;

is_display( [ [TEXT("+-------------+")],
              [TEXT("| >Click me<  |")],
              [TEXT("+-------------+")] ],
            'Display after focus' );

is( $clicked, 0, '$clicked before mouse release' );

pressmouse( release => 1, 1, 10 );

flush_tickit;

is_display( [ [TEXT("+-------------+")],
              [TEXT("| >Click me<  |")],
              [TEXT("+-------------+")] ],
            'Display after mouse release' );

is( $clicked, 1, '$clicked after mouse release' );