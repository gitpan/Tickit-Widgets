#!/usr/bin/perl

use strict;
use warnings;

use Tickit;

use Tickit::Widget::Border;
use Tickit::Widget::Static;

my $box = Tickit::Widget::Border->new(
   h_border => 4, v_border => 2,
   bg => "green",
   child => Tickit::Widget::Static->new(
      text => "Hello, world!",
      align => "centre", valign => "middle",
      bg => "black",
   ),
);

Tickit->new( root => $box )->run;
