#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widgets qw( Box Button VBox );

my $box = Tickit::Widget::Box->new(
   h_border => 10,
   v_border => 4,
   child => my $vbox = Tickit::Widget::VBox->new( spacing => 2, bg => "black" ),
);

foreach my $colour (qw( red blue green yellow )) {
   $vbox->add(
      Tickit::Widget::Button->new(
         label => $colour,
         on_click => sub { $box->pen->chattr( bg => $colour ) },
      )
   );
}

my $tickit = Tickit->new( root => $box );

$vbox->add(
   Tickit::Widget::Button->new(
      label => "Quit",
      on_click => sub { $tickit->stop },
   )
);

$tickit->run;
