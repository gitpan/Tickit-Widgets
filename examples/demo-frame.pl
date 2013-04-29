#!/usr/bin/perl

use strict;
use warnings;

use Tickit;
use Tickit::Widgets qw( Static VBox Frame );

my $vbox = Tickit::Widget::VBox->new( spacing => 1 );

my $fg = 1;
foreach my $linetype ( qw( ascii single double thick solid_inside solid_outside ) ) {
   $vbox->add( Tickit::Widget::Frame->new(
      style => { 
         linetype => $linetype,
         frame_fg => $fg++,
      },
      child => Tickit::Widget::Static->new( text => $linetype, align => 0.5 )
   ) );
}

Tickit->new( root => $vbox )->run;
