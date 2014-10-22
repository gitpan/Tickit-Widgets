#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2012 -- leonerd@leonerd.org.uk

package Tickit::Widgets;

use strict;
use warnings;

our $VERSION = '0.16';

=head1 NAME

C<Tickit::Widgets> - load several L<Tickit::Widget> classes at once

=head1 SYNOPSIS

 use Tickit::Widgets qw( Static VBox HBox );

Equivalent to

 use Tickit::Widget::Static;
 use Tickit::Widget::VBox;
 use Tickit::Widget::HBox;

=head1 DESCRIPTION

This module provides an C<import> utility to simplify code that uses many
different L<Tickit::Widget> subclasses. Instead of a C<use> line per module,
you can simply C<use> this module and pass it the base name of each class.
It will C<require> each of the modules.

Note that because each Widget module should be a pure object class with no
exports, this utility does not run the C<import> method of the used classes.

=cut

sub import
{
   shift; # class

   # Only need to 'require' the modules because they're all clean object
   # classes, no need to import any of them
   foreach ( @_ ) {
      my $class = $_; # $_ is alias to read-only values;
      local $_; # placate bug in Tickit::RenderContext 0.06

      $class = "Tickit::Widget::$class" unless $class =~ m/::/;

      ( my $file = "$class.pm" ) =~ s{::}{/}g;

      require $file;
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
