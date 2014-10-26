use strict;
use HTML::Manipulator;

package HTML::Manipulator::Document;

our $VERSION = '0.03';

use Carp;

sub from_string{
	my ($class, $html) = @_;
	my $self = bless 
		{ html => $html }, $class;
	return $self;
}

sub from_file{
	my ($class, $file) = @_;
	my $html;
	if ( UNIVERSAL::isa($file, 'GLOB') or UNIVERSAL::isa(\$file, 'GLOB') ){
		$html = join '', <$file>;
	}else{
		require FileHandle;
		my $fh = new FileHandle($file, 'r');
		croak "could not open the file $file for reading: $!" unless $fh;
		$html = join '', <$fh>;
		$fh->close;
	}
	return $class->from_string($html);
}

sub as_string{
	my ($self) = @_;
	return $self->{html};
}

sub replace{
	my ($self, @args) = @_;
	$self->{html}
		= HTML::Manipulator::replace(
			$self->{html}, @args);
}

sub extract{
	my ($self, @args) = @_;
	HTML::Manipulator::extract(
			$self->{html}, @args);
}

sub extract_content{
	my ($self, @args) = @_;
	HTML::Manipulator::extract_content(
			$self->{html}, @args);
}

sub extract_all{
	my ($self, @args) = @_;
	HTML::Manipulator::extract_all(
			$self->{html}, @args);
}

sub extract_all_content{
	my ($self, @args) = @_;
	HTML::Manipulator::extract_all_content(
			$self->{html}, @args);
}

sub extract_all_ids{
	my ($self, @args) = @_;
	HTML::Manipulator::extract_all_ids(
			$self->{html}, @args);
}


1;
__END__

=head1 NAME

HTML::Manipulator::Document - object-oriented interface to HTML::Manipulator

=head1 SYNOPSIS

   use HTML::Manipulator::Document;
   
   my $doc = HTML::Manipulator::Document->from_file('test.html');
   print $doc->replace('headline'=>'New Headline');
   
   print $doc->as_string;
 
=head1 DESCRIPTION

This module provides an object-oriented interface
to the functions of the L<HTML::Manipulator> module.
It also has an additional feature to load HTML from
file.

You use it by calling one of the two constructor
methods, which return an object of this class.
The object has methods that mirror the functions
of HTML::Manipulator.

=head2 Constructors

Instances can be be created from HTML documents
in memory (contained in a string) or from a file.

   my $doc = HTML::Manipulator::Document->from_string('<html>blah</html>');
   
   my $doc = HTML::Manipulator::Document->from_file('test.html');
   
 The from_file() constructor takes a file handle
 or a file name.
   
=head2 HTML::Manipulator methods

All of the functions of L<HTML::Manipulator>
are available as methods. 

In HTML::Manipulator,
the first parameter is always the HTML text.
In the object-oriented interface the HTML document
was already specified in the constructor, making
the parameter obsolete. You must therefore
omit that first parameter. 

For example

   my $new = HTML::Manipulator::replace($html, 
        title => 'New news', headline77=>'All clear?');

becomes

  my $obj = HTML::Manipulator::Document->from_string($html);
  my $new = $obj->replace(
  	 title => 'New news', headline77=>'All clear?');

The methods return the same results as the functions 
they wrap. See L<HTML::Manipulator> for details
on what functions there are and how they work.

=head2 replace() method

In addition to returning the new HTML text,
the replace() method also changes the content
of the HTML document represented by the object.

=head2 as_string() method

Use this method to get the HTML content
from the object.

=head1 SEE ALSO

L<HTML::Manipulator>

L<perltoot>


=head1 AUTHOR

Thilo Planz, E<lt>planz@epost.deE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
