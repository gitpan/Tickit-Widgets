#!/usr/bin/perl

use strict;

use Test::More;
use Test::Identity;

use Tickit::Test;

use Tickit::Widget::Static;
use Tickit::Widget::GridBox;

my $win = mk_window;

my @statics = map { Tickit::Widget::Static->new( text => "Widget $_" ) } 0 .. 5;

my $widget = Tickit::Widget::GridBox->new;

ok( defined $widget, 'defined $widget' );

$widget->add( 0, 0, $statics[0], col_expand => 1, row_expand => 1 );
$widget->add( 0, 1, $statics[1], col_expand => 1, row_expand => 1 );
$widget->add( 1, 0, $statics[2], col_expand => 1, row_expand => 1 );
$widget->add( 1, 1, $statics[3], col_expand => 1, row_expand => 1 );

is( $widget->lines, 2, '$widget->lines after ->add' );
is( $widget->cols, 16, '$widget->cols after ->add' );

$widget->set_window( $win );

ok( defined $statics[0]->window, '$statics[0] has window after $widget->set_window' );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(32), TEXT("Widget 1"), BLANK(32)],
              BLANKLINES(11),
              [TEXT("Widget 2"), BLANK(32), TEXT("Widget 3"), BLANK(32)],
              BLANKLINES(12) ],
            'Display initially' );

$widget->set_col_spacing( 10 );
$widget->set_row_spacing( 3 );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(27+10), TEXT("Widget 1"), BLANK(27)],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(27+10), TEXT("Widget 3"), BLANK(27)],
              BLANKLINES(10) ],
            'Display after changing spacing' );

$widget->add( 0, 2, $statics[4] ); # no expand
$widget->add( 1, 2, $statics[5] ); # no expand

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(18+10), TEXT("Widget 1"), BLANK(18+10), TEXT("Widget 4")],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(18+10), TEXT("Widget 3"), BLANK(18+10), TEXT("Widget 5")],
              BLANKLINES(10) ],
            'Display after adding more cells without expand' );

$widget->remove( 1, 1 );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(18+10), TEXT("Widget 1"), BLANK(18+10), TEXT("Widget 4")],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(18+10), BLANK(8), BLANK(18+10), TEXT("Widget 5")],
              BLANKLINES(10) ],
            'Display after removing a cell' );

$widget->remove( 1, 2 );
$widget->remove( 0, 2 );

flush_tickit;

is_display( [ [TEXT("Widget 0"), BLANK(27+10), TEXT("Widget 1"), BLANK(27)],
              BLANKLINES(10+3),
              [TEXT("Widget 2"), BLANK(27+10), BLANK(8), BLANK(27)],
              BLANKLINES(10) ],
            'Display after removing an entire column' );

done_testing;
