#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::CheckButton;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderContext;

our $VERSION = '0.07';

use Carp;

use Tickit::Utils qw( textwidth );
use List::MoreUtils qw( any );

=head1 NAME

C<Tickit::Widget::CheckButton> - a widget allowing a toggle true/false option

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::CheckButton;
 use Tickit::Widget::VBox;

 my $vbox = Tickit::Widget::VBox->new;
 $vbox->add( Tickit::Widget::CheckButton->new(
       caption => "Check button $_",
 ) ) for 1 .. 5;

 Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which allows a true/false selection. It displays
a clickable indication of status and a caption. Clicking on the status or
caption inverts the status of the widget.

This widget is part of an experiment in evolving the design of the
L<Tickit::Style> widget integration code, and such is subject to change of
details.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item check => PEN

The pen used to render the check marker

=back

The following style keys are used:

=over 4

=item check => STRING

The text used to indicate the active status

=item spacing => INT

Number of columns of spacing between the check mark and the caption text

=back

The following style tags are used:

=over 4

=item :active

Set when this button's status is true

=back

=cut

style_definition base =>
   check_fg => "hi-white",
   check_b  => 1,
   check    => "[ ]",
   spacing  => 2;

style_definition ':active' =>
   b        => 1,
   check    => "[X]";

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $checkbutton = Tickit::Widget::CheckButton->new( %args )

Constructs a new C<Tickit::Widget::CheckButton> object.

Takes the following named argmuents

=over 8

=item label => STRING

The label text to display alongside this button.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{label} = $args{label};

   return $self;
}

sub lines
{
   my $self = shift;
   return 1;
}

sub cols
{
   my $self = shift;
   return textwidth( $self->get_style_values( "check" ) ) +
          $self->get_style_values( "spacing" ) +
          textwidth( $self->{label} );
}

=head1 ACCESSORS

=cut

=head2 $label = $checkbutton->label

=head2 $checkbutton->set_label( $label )

Returns or sets the label text of the button.

=cut

sub label
{
   my $self = shift;
   return $self->{label};
}

sub set_label
{
   my $self = shift;
   ( $self->{label} ) = @_;
   $self->reshape;
   $self->redraw;
}

sub on_style_changed_values
{
   my $self = shift;
   my %values = @_;

   foreach (qw( spacing )) {
      next if !$values{$_};

      $self->reshape;
      $self->redraw;
      return;
   }

   foreach (qw( check )) {
      next if !$values{$_};
      next if textwidth( $values{$_}[0] ) == textwidth( $values{$_}[1] );

      $self->reshape;
      $self->redraw;
      return;
   }

   $self->redraw;
}

=head1 METHODS

=cut

=head2 $checkbutton->activate

Sets this button's active state to true.

=cut

sub activate
{
   my $self = shift;
   $self->{active} = 1;
   $self->set_style_tag( active => 1 );
}

=head2 $checkbutton->deactivate

Sets this button's active state to false.

=cut

sub deactivate
{
   my $self = shift;
   $self->{active} = 0;
   $self->set_style_tag( active => 0 );
}

=head2 $active = $checkbutton->is_active

Returns this button's active state.

=cut

sub is_active
{
   my $self = shift;
   return !!$self->{active};
}

use constant CLEAR_BEFORE_RENDER => 0;
sub render
{
   my $self = shift;
   my %args = @_;
   my $win = $self->window or return;

   my $rc = Tickit::RenderContext->new( lines => $win->lines, cols => $win->cols );
   $rc->clip( $args{rect} );
   $rc->setpen( $self->pen );

   $rc->clear;

   $rc->goto( 0, 0 );

   $rc->text( $self->get_style_values( "check" ), $self->get_style_pen( "check" ) );
   $rc->erase( $self->get_style_values( "spacing" ) );
   $rc->text( $self->{label} );
   $rc->erase_to( $win->cols );

   $rc->flush_to_window( $win );
}

sub on_mouse
{
   my $self = shift;
   my ( $ev, $button, $line, $col ) = @_;
   return unless $ev eq "press" and $button == 1;
   return 1 unless $line == 0;

   $self->is_active ? $self->deactivate : $self->activate;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
