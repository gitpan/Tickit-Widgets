#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Tickit::Widget::Fill;

use strict;
use warnings;
use 5.010; # //
use base qw( Tickit::Widget );
use Tickit::Style;

our $VERSION = '0.19';

use Tickit::Utils qw( textwidth );

=head1 NAME

C<Tickit::Widget::Fill> - fill an area with repeated text

=head1 DESCRIPTION

This class provides a widget which displays a given piece of text repeatedly
over its entire area. By default the text is a single space, meaning the area
will be entirely drawn with spaces.

=head1 STYLE

The default style pen is used as the widget pen.

The following style keys are used:

=over 4

=item text => STRING

The text to display in a repeating pattern on the window.

=item skew => INT

If defined, successive lines will be advanced by this number of columns (which
may be negative) to create a skewed repeating pattern.

=back

=cut

style_definition base =>
   text => " ";

style_redraw_keys qw( text skew );

use constant WIDGET_PEN_FROM_STYLE => 1;

sub lines { 1 }
sub cols  { 1 }

sub render_to_rb
{
   my $self = shift;
   my ( $rb, $rect ) = @_;

   my ( $text, $skew ) = $self->get_style_values(qw( text skew ));
   $skew //= 0;

   my $len  = textwidth( $text );

   my $left = $rect->left;
   $left -= $left % $len;

   my $repeat = int( ( $rect->right - $left + $len - 1 ) / $len );
   $repeat++ if $skew;

   foreach my $line ( $rect->linerange ) {
      my $lineskew = ( $line * $skew ) % $len;
      $lineskew -= $len if $skew;

      $rb->goto( $line, $left + $lineskew );
      $rb->text( $text x $repeat );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
