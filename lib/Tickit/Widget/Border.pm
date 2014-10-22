#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2012 -- leonerd@leonerd.org.uk

package Tickit::Widget::Border;

use strict;
use warnings;
use base qw( Tickit::SingleChildWidget );
use Tickit::WidgetRole::Borderable;

our $VERSION = '0.05';

=head1 NAME

C<Tickit::Widget::Border> - draw a fixed-size border around a widget

=head1 SYNOPSIS

 use Tickit;
 use Tickit::Widget::Border;
 use Tickit::Widget::Static;

 my $hello = Tickit::Widget::Static->new(
    text   => "Hello, world",
    align  => "centre",
    valign => "middle",
 );

 my $border = Tickit::Widget::Border->new;

 $border->set_child( $hello );

 Tickit->new( root => $border )->run;

=head1 DESCRIPTION

This container widget holds a single child widget and implements a border by
using L<Tickit::WidgetRole::Borderable>.

=cut

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = $class->SUPER::new( %args );

   $self->_border_init( \%args );

   return $self;
}

sub lines
{
   my $self = shift;
   my $child = $self->child;
   return $self->top_border +
          ( $child ? $child->lines : 0 ) +
          $self->bottom_border;
}

sub cols
{
   my $self = shift;
   my $child = $self->child;
   return $self->left_border +
          ( $child ? $child->cols : 0 ) +
          $self->right_border;
}

sub children_changed { shift->set_child_window }
sub reshape          { shift->set_child_window }

sub set_child_window
{
   my $self = shift;

   my $window = $self->window or return;
   my $child  = $self->child  or return;

   my @geom = $self->get_border_geom;

   if( @geom ) {
      if( my $childwin = $child->window ) {
         $childwin->change_geometry( @geom );
      }
      else {
         my $childwin = $window->make_sub( @geom );
         $child->set_window( $childwin );
      }
   }
   else {
      if( $child->window ) {
         $child->set_window( undef );
      }
   }
}

use constant CLEAR_BEFORE_RENDER => 0;

sub render
{
   my $self = shift;
   my %args = @_;

   my $win = $self->window or return;
   $win->is_visible or return;
   my $rect = $args{rect};

   foreach my $line ( $rect->top .. $self->top_border - 1 ) {
      $win->clearline( $line );
   }
   
   my $left_border  = $self->left_border;
   my $right_border = $self->right_border;
   my $right_border_at = $win->cols - $right_border;

   if( $self->child and $left_border + $right_border < $win->cols ) {
      foreach my $line ( $self->top_border .. $win->lines - $self->bottom_border ) {
         if( $left_border > 0 ) {
            $win->goto( $line, 0 );
            $win->erasech( $left_border );
         }

         if( $right_border > 0 ) {
            $win->goto( $line, $right_border_at );
            $win->erasech( $right_border );
         }
      }
   }
   else {
      foreach my $line ( $self->top_border .. $win->lines - $self->bottom_border - 1 ) {
         $win->clearline( $line );
      }
   }

   foreach my $line ( $win->lines - $self->bottom_border .. $rect->bottom - 1 ) {
      $win->clearline( $line );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
