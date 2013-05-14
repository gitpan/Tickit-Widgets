#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2013 -- leonerd@leonerd.org.uk

package Tickit::Widget::RadioButton;

use strict;
use warnings;
use base qw( Tickit::Widget );
use Tickit::Style;
use Tickit::RenderContext;

our $VERSION = '0.08';

use Carp;

use Tickit::Utils qw( textwidth );
use List::MoreUtils qw( any );

=head1 NAME

C<Tickit::Widget::RadioButton> - a widget allowing a selection from multiple
options

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::RadioButton;
 use Tickit::Widget::VBox;

 my $group = Tickit::Widget::RadioButton::Group->new;

 my $vbox = Tickit::Widget::VBox->new;
 $vbox->add( Tickit::Widget::RadioButton->new(
       caption => "Radio button $_",
       group   => $group,
 ) ) for 1 .. 5;

 Tickit->new( root => $vbox )->run;

=head1 DESCRIPTION

This class provides a widget which allows a selection of one value from a
group of related options. It provides a clickable area and a visual indication
of which button in the group is the one currently active. Selecting a new
button within a group will unselect the previously-selected one.

This widget is part of an experiment in evolving the design of the
L<Tickit::Style> widget integration code, and such is subject to change of
details.

=head1 STYLE

The default style pen is used as the widget pen. The following style pen 
prefixes are also used:

=over 4

=item tick => PEN

The pen used to render the tick marker

=back

The following style keys are used:

=over 4

=item tick => STRING

The text used to indicate the active button

=item spacing => INT

Number of columns of spacing between the tick mark and the caption text

=back

The following style tags are used:

=over 4

=item :active

Set when this button is the active one of the group.

=back

=cut

style_definition base =>
   tick_fg => "hi-white",
   tick_b  => 1,
   tick    => "( )",
   spacing => 2;

style_definition ':active' =>
   b        => 1,
   tick     => "(*)";

use constant WIDGET_PEN_FROM_STYLE => 1;

=head1 CONSTRUCTOR

=cut

=head2 $radiobutton = Tickit::Widget::RadioButton->new( %args )

Constructs a new C<Tickit::Widget::RadioButton> object.

Takes the following named argmuents

=over 8

=item label => STRING

The label text to display alongside this button.

=item group => Tickit::Widget::RadioButton::Group

Optional. If supplied, the group that the button should belong to. If not
supplied, a new group will be constructed that can be accessed using the
C<group> accessor.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $self = $class->SUPER::new( %args );

   $self->{label} = $args{label};
   $self->{group} = $args{group} || Tickit::Widget::RadioButton::Group->new;

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
   return textwidth( $self->get_style_values( "tick" ) ) +
          $self->get_style_values( "spacing" ) +
          textwidth( $self->{label} );
}

=head1 ACCESSORS

=cut

=head2 $group = $radiobutton->group

Returns the C<Tickit::Widget::RadioButton::Group> this button belongs to.

=cut

sub group
{
   my $self = shift;
   return $self->{group};
}

=head2 $label = $radiobutton->label

=head2 $radiobutton->set_label( $label )

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

   foreach (qw( tick )) {
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

=head2 $radiobutton->activate

Sets this button as the active member of the group, deactivating the previous
one.

=cut

sub activate
{
   my $self = shift;
   my $group = $self->{group};

   if( my $old = $group->active ) {
      $old->set_style_tag( active => 0 );
   }

   $group->set_active( $self );

   $self->set_style_tag( active => 1 );
}

=head2 $active = $radiobutton->is_active

Returns true if this button is the active button of the group.

=cut

sub is_active
{
   my $self = shift;
   return $self->group->active == $self;
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

   $rc->text( $self->get_style_values( "tick" ), $self->get_style_pen( "tick" ) );
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

   $self->activate;
}

package # hide from indexer
   Tickit::Widget::RadioButton::Group;
use Scalar::Util qw( weaken refaddr );

=head1 GROUPS

Every C<Tickit::Widget::RadioButton> belongs to a group. Only one button can
be active in a group at any one time. The C<group> accessor returns the group
the button is a member of. The following methods are available on it.

A group can be explicitly created to pass to a button's constructor, or one
will be implicitly created for a button if none is passed.

=cut

=head2 $group = Tickit::Widget::RadioButton::Group->new

Returns a new group.

=cut

sub new
{
   my $class = shift;
   return bless \(my $self), $class;
}

=head2 $radiobutton = $group->active

Returns the button which is currently active in the group

=cut

sub active
{
   my $self = shift;
   return $$self;
}

sub set_active
{
   my $self = shift;
   ( $$self ) = @_;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
