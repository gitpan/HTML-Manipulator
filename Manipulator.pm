use 5.008;
use strict;

package HTML::Manipulator;

our $VERSION = '0.04';


sub replace{
    my ($html, %data) = @_;
    my $parser = new HTML::Manipulator::Replacer( 
        \%data );
    if ( UNIVERSAL::isa($html, 'GLOB') or UNIVERSAL::isa(\$html, 'GLOB') ){
          $parser->parse_file($html);
    }
    else{
        $parser->parse($html);
        $parser->eof;
    }
    return $parser->{_collect};
}

sub replace_title{
    my ($html, $title) = @_;
    my $parser = new HTML::Manipulator::TitleReplacer( $title);
    if ( UNIVERSAL::isa($html, 'GLOB') or UNIVERSAL::isa(\$html, 'GLOB') ){
          $parser->parse_file($html);
    }
    else{
        $parser->parse($html);
        $parser->eof;
    }
    return $parser->{_collect};
}

sub extract{
    my ($html, $id) = @_;
    my $result = extract_all($html,$id);
    return ref $result ? $result->{$id} : undef;
}

sub extract_content{
    my ($html, $id) = @_;
    my $result = extract_all_content($html,$id);
    return ref $result ? $result->{$id} : undef;
}

sub extract_all{
    my ($html, @ids) = @_;
    if ( UNIVERSAL::isa($html, 'GLOB') or UNIVERSAL::isa(\$html, 'GLOB') ){
        $html = join '', <$html>;
    }
    @ids = keys %{extract_all_ids($html)} unless @ids;
    return {} unless @ids;
    my %result;
      while (@ids){
        my $parser = new HTML::Manipulator::Extractor(@ids);
              
        $parser->parse($html);
        $parser->eof;
        if (ref $parser->{_found} and keys %{$parser->{_found}}){
            %result = (%result, %{$parser->{_found}}) ;
            @ids = grep {not exists $result{$_}} @ids;
        }
        else {
            @ids = ();
        }
    }
    return \%result;
}

sub extract_all_content{
    my ($html, @ids) = @_;
    my $result = extract_all($html, @ids);
    return {} unless ref $result;
    return { map { ( $_ => $result->{$_}{_content} ) } keys %$result };
}

sub extract_all_ids{
    my ($html) = @_;
    my $parser = new HTML::Manipulator::IDExtractor();
    if ( UNIVERSAL::isa($html, 'GLOB') or UNIVERSAL::isa(\$html, 'GLOB') ){
          $parser->parse_file($html);
    }
    else{
        $parser->parse($html);
        $parser->eof;
    }
    return $parser->{_found} || {} ;
}

sub extract_title{
	my ($html) = @_;
	my $parser = new HTML::Manipulator::TitleExtractor();
	 if ( UNIVERSAL::isa($html, 'GLOB') or UNIVERSAL::isa(\$html, 'GLOB') ){
          $parser->parse_file($html);
    }
    else{
        $parser->parse($html);
        $parser->eof;
    }
    return $parser->{_found};
}

package HTML::Manipulator::Replacer;
use base qw(HTML::Parser);

sub start_handler{
    my ($self, $type, $attr, $text, $skip) = @_;
    my $id = $attr->{id};
    if (exists $self->{_watch_for}){
        $self->{_watch_for_depth}++ if $self->{_watch_for} eq $type;
        return;
    }
     $self->{_collect} .=  $skip;
    unless ($id and exists $self->{_update_ids}{$id}){
         $self->{_collect} .=  $text;
        return;
    }
    my $content = $self->{_update_ids}{$id};
    my %new_values;
    if (ref $content){
        %new_values = %$content;
        foreach (keys %new_values){
            if ($_ ne lc $_){
                 $new_values{lc $_} = delete $new_values{$_};
            }
        }
        
        $content = delete $new_values{'_content'};
    }
    
    if (%new_values){
        my %attr = (%$attr, %new_values);
        $self->{_collect} .=  "<$type";
        foreach (sort keys %attr){
            if(index ($attr{$_}, "'") == -1 ){ 
                 $self->{_collect} .=   qq[ $_='$attr{$_}'];
            }else{
                $self->{_collect} .=   qq[ $_="$attr{$_}"];
            }
        } 
        $self->{_collect} .=  ">";
    }else{
        $self->{_collect} .= $text;
    }
    if ($content){
        $self->{_watch_for} = $type;
         $self->{_collect} .=  $content;
    }
}

sub end_handler{
    my ($self, $type, $text, $skip) = @_;
    unless (exists $self->{_watch_for}) {
         $self->{_collect} .=  $skip;
         $self->{_collect} .=  $text;
        return;
    }
    if ($type eq $self->{_watch_for}){
        $self->{_watch_for_depth}--;
        if ($self->{_watch_for_depth}){
             $self->{_collect} .=  $text;
            delete $self->{_watch_for};
        }
    }
}

sub end_document_handler{
    my ($self, $text) = @_;
    $self->{_collect} .= $text;
}



sub new{
    my ($class, $args) = @_;
    my $self= HTML::Parser::new ( $class,
        start_h => ['start_handler', "self,tagname, attr, text, skipped_text"],
        end_h => ['end_handler', "self,tagname, text, skipped_text"],
        end_document_h =>['end_document_handler', "self, skipped_text"],,
    );
    
    $self->{_update_ids} = $args;
    $self->{_collect} = '';
    return $self;
}


package HTML::Manipulator::Extractor;
use base qw(HTML::Parser);

sub start_handler{
    my ($self, $type, $attr, $text, $skip) = @_;
    my $id = $attr->{id};
    if (exists $self->{_watch_for}){
         $self->{_found}{$self->{_watch_for_id}}{_content} .= $skip . $text;
         $self->{_watch_for_depth}++ if $self->{_watch_for} eq $type;
         return;
    }
    
    unless ($id and exists $self->{_extract_ids}{$id}){
        return;
    }
    $self->{_found}{$id} = $attr;
    $self->{_found}{$id}{_start_tag} = $text;
    $self->{_watch_for_id} = $id;
    $self->{_watch_for} = $type;
}

sub end_handler{
    my ($self, $type, $text, $skip) = @_;
    unless (exists $self->{_watch_for} and $type eq $self->{_watch_for}){
        if (exists $self->{_watch_for}){
            $self->{_found}{$self->{_watch_for_id}}{_content} .= $skip . $text;
         }
        return;
    }
     $self->{_found}{$self->{_watch_for_id}}{_content} .= $skip;
     
    $self->{_watch_for_depth}--;
    if ($self->{_watch_for_depth}>=0){
        $self->{_found}{$self->{_watch_for_id}}{_content} .=  $text;
        return;
    } 
    $self->{_found}{$self->{_watch_for_id}}{_end_tag} = $text;
    delete $self->{_watch_for};
}


sub new{
    my ($class, @args) = @_;
    my $self= HTML::Parser::new ( $class,
        start_h => ['start_handler', "self,tagname, attr, text, skipped_text"],
        end_h => ['end_handler', "self,tagname, text, skipped_text"],
    );
    
    my %args = map {( $_ => 1)} @args;
    $self->{_extract_ids} = \%args;
    
    return $self;
}

package HTML::Manipulator::IDExtractor;
use base qw(HTML::Parser);

sub start_handler{
    my ($self, $type, $attr) = @_;
    $self->{_found}{$attr->{id}} = $type if exists  $attr->{id};
}

sub new{
    my ($class, @args) = @_;
    my $self= HTML::Parser::new ( $class,
        start_h => ['start_handler', "self, tagname, attr"],
    );
    
    return $self;
}

package HTML::Manipulator::TitleExtractor;
use base qw(HTML::Parser);

sub start_handler{
    my ($self, $type, $text, $skip) = @_;
    if (exists $self->{_watch_for}){
         $self->{_found} .= $skip . $text;
         return;
    }
    if ($type eq 'title'){
	    $self->{_watch_for} = 1;
    }
}

sub end_handler{
	 my ($self, $type, $text, $skip) = @_;
	if (exists $self->{_watch_for}){
		$self->{_found} .= $skip;
		if ($type eq 'title'){
			delete $self->{_watch_for};
		}
		else{
			$self->{_found} .= $text;
		}
	}
   }


sub new{
    my ($class, @args) = @_;
    my $self= HTML::Parser::new ( $class,
        start_h => ['start_handler', "self,tagname, text, skipped_text"],
        end_h => ['end_handler', "self,tagname, text, skipped_text"],
    );
    
    return $self;
}

package HTML::Manipulator::TitleReplacer;
use base qw(HTML::Parser);

sub start_handler{
    my ($self, $type, $text, $skip) = @_;
    unless (exists $self->{_watch_for}){
	    $self->{_collect} .= $skip . $text;
	    if ($type eq 'title'){
		    $self->{_watch_for} = 1;
	    }
    }
}

sub end_handler{
	 my ($self, $type, $text, $skip) = @_;
	if (exists $self->{_watch_for}){
		if ($type eq 'title'){
			delete $self->{_watch_for};
			$self->{_collect} .= $self->{_new_title};
		}
		else{
			$self->{_collect} .= $skip;
		}
		$self->{_collect} .= $text;
	}
	else{
		$self->{_collect} .= $skip.$text;
	}
   }

sub end_document_handler{
    my ($self, $text) = @_;
    $self->{_collect} .= $text;
}

sub new{
    my ($class, $title) = @_;
    my $self= HTML::Parser::new ( $class,
        start_h => ['start_handler', "self,tagname, text, skipped_text"],
        end_h => ['end_handler', "self,tagname, text, skipped_text"],
	end_document_h =>['end_document_handler', "self, skipped_text"],
    );
    $self->{_new_title} = $title;
    return $self;
}



1;
__END__

=head1 NAME

HTML::Manipulator - Perl extension for manipulating HTML files

=head1 SYNOPSIS

  use HTML::Manipulator;
  
  my $html = <<HTML;
    <h1 id=title>Old news</h1>
    <a href='http://www.google.com' id=link>Google</a>....
  HTML
  
  # replace a tag content
  my $new = HTML::Manipulator::replace($html, title => 'New news');
  
  # replace a tag attribute and content
  my $new = HTML::Manipulator::replace($html, link => { 
    _content => 'Slashdot',
     href=>'http://www.slashdot.org/' }
    );

  # extract a tag content
  my $content = HTML::Manipulator::extract_content($html, 'link');
  
  # extract a tag content and attributes
  my $tag =  HTML::Manipulator::extract($html, 'link');
    # returns a hash ref like
    # { href => 'http://www.google.com', id => 'link', _content => 'Google' }

=head1 DESCRIPTION

This module manipulates of the contents of HTML files.
It can query and replace the content or attributes of any HTML tag.

The advertised usage pattern is to update static HTML files. 


=head2 ANOTHER TEMPLATE ENGINE ? NO !

HTML::Manipulator is NOT yet another templating module.
There are, for example, no template files. It works on normal HTML files
without any special markup (you only have to give element IDs to tags you are
interested in). 

While you could probably use this module for
producing your web application's output, DON'T.
It does not offer a lot of features for this area
(no loops, no conditionals, no includes) and is not
optimized for performance. Have a look at
L<HTML::Template> instead.

=head2 ABOUT THE INPUT HTML FILES

HTML::Manipulator is meant to work on real-life HTML files (in all their non-standards-compliant ugliness). It uses the HTML::Parser module to find
elements (tags) inside those files, which you can then replace or modify.
All you have to do is give those elements a DOM ID, for example

    <h3 id=headline77>Headline</h3>
    
No other markup is necessary.

=head3 Malformed HTML (is fine)

HTML::Manipulator tries to cope with malformed input data.
All you have to ensure is that you properly close
the element you are working on (any other tags can be unbalanced) and that the IDs are unique.
 It will also preserve the content outside the element you asked it to operate on. It does not
rewrite your HTML any more than it has to. 

=head3 Case insensitivity issues

HTML is case insensitive in its tag and attribute names.
This means that

    <h3 id=headline77>Headline</h3>
    
and

    <H3 iD=headline77>Headline</h3>
    
are treated as identical. 

However, HTML::Manipulator respects
case when comparing the IDs of elements (not sure about the HTML standard here), so that you could NOT address above h3 element as HeadLine77.

When HTML::Manipulator has to rewrite tags (this happens
when you ask it to change element attributes) it will output
the tag and attribute names as lower-case. It will also
rearrange their order. When changing only
the content of an element, it preserves the original opening and
closing tags.

=head2 FUNCTIONS TO CHANGE CONTENT

You can change the content or attributes of any HTML element with an attached ID.

=head3 Replace the content of one element

    my $new = HTML::Manipulator::replace($html, title => 'New news');
    
The function takes as input the HTML data and returns the modified data
(as a long scalar).
  
=head3 Replace the content of many elements

     my $new = HTML::Manipulator::replace($html, 
        title => 'New news', headline77=>'All clear?');

You can just pass many IDs and new contents to the function as well.
The caveat here is that if those elements are nested, only the outermost
will be applied: The complete content of the outermost element will
be replaced with the new content, eliminating any nested tags.
Even if the new content contains nested elements, these will not be 
evaluated. No recursion today.

=head3 Replace attribute values

If you want to replace attribute values (such as a link href), you
use the same function described above, but 
pass a hashref instead of the string with the new content:

    my $new = HTML::Manipulator::replace($html, link => { 
         href=>'http://www.slashdot.org/' }
    );

The hashref can contain as many key/value pairs as you want.
Any attributes that you specify here will appear in the output HTML.
Any attributes that you do not specify will retain their old value.

=head3 Replace attribute values and content

You can also change content and attributes at the same time, by 
adding the special "attribute" _content to the attribute hashref.

     my $new = HTML::Manipulator::replace($html, link => { 
         _content => 'Slashdot',
        href=>'http://www.slashdot.org/' }
    );

=head3 Replace the document title

You can set the document title (the stuff between
the <title> tags) like

	my $new = HTML::Manipulator::replace_title($html, 'new title');

=head2 FUNCTIONS TO EXTRACT CONTENT

In addition to replacing parts of the HTML document, you can also query it
for the current content.


=head3 Extract the content of an element

    my $content = HTML::Manipulator::extract_content($html, 'link');
  
gives you a scalar containing the content of the tag with the ID 'link'.

=head3 Extract the content of all elements

    my $content = HTML::Manipulator::extract_all_content($html);

gives you a hashref with all element IDs as keys and their contents as values.

=head3 Extract the content and attributes

    my $content = HTML::Manipulator::extract($html, 'link');
    
gives you a hashref with information about the tag with the ID 'link'.
There is a key for every attribute in the tag, and the special key '_content'
which contains the content. The structure of the hashref is identical to what
you would use when calling the replace function.

There is also a function to get information about all elements (that have an ID):

    my $content = HTML::Manipulator::extract_all($html);
    
This returns a hashref of hashrefs, so that you could get the
href of the "link" element like $content->{link}{href}.


=head3 Extract some elements

You can selectively use the extract_all* functions by passing
in the IDs you are interested in. This is optional. The default returns
data for all elements with IDs.

    my $content = HTML::Manipulator::extract_all_content
        ($html, 'one', 'two', 'three');

=head3 Find out all element IDs

You can query for a list of all element IDs and their tag type.

	$data = HTML::Manipulator::extract_all_ids($before);

This returns a hashref where the element IDs of the document
are they keys. The associated value is the type of the 
element (the tag type, such as div, span, a), which
is returned as lowercase.

=head3 Find out the document title

	my $title = HTML::Manipulator::extract_title($html);


=head2 USING FILEHANDLES

You can also call all of the above functions with a file handle instead of the
string holding the HTML. HTML::Manipulator (or HTML::Parser deeper down the line)
will read from the file.

  use FileHandle;
  my $new = HTML::Manipulator::replace(new FileHandle('myfile.html'), title => 'New news');

  open IN, 'myfile.html';
  my $new = HTML::Manipulator::replace(*IN, title => 'New news');
  close IN;

HTML::Manipulator will only read from the file handles you give it.
It does not change them. Nor does it open them,
you have to have done that yourself. Or you can
use L<HTML::Manipulator::Document>, which does
open files.


=head2 EXPORT

The module exports none of its functions.
You have to prefix the full module name to use them.

If you want an object-oriented interface instead,
consider L<HTML::Manipulator::Document>.

=head1 SEE ALSO

=head2 Processing HTML documents

HTML::Manipulator uses L<HTML::Parser> for parsing the input file. 
If you find yourself in the unfortunate situation of having to process HTML, have a look
at that module. 

For specific purposes there are also some other modules to work with, for example

=over

=item *

L<HTML::HeadParser> extracts info from the <head> section


=item *

L<HTML::LinkExtor> and L<HTML::LinkExtractor> extract links

=item *

L<HTML::FillInForm> populates HTML forms with data


=back


=head2 Producing HTML output (templating engines)

HTML::Manipulator is not a templating engine. 
You should not use it to produce output for your CGI script.
If you want to do that, take a look at

=over

=item *

L<HTML::Template> (personal favorite)

=item *

L<Template> Toolkit (also very popular)

=item *

L<Petal> (innovative, uses attributes rather than tags for markup) 

=back

=head2 Managing complete (static) web sites

A great tool to produce and manage a large number
of related static HTML pages is L<HTML::WebMake>.



=head1 BUGS

This is a young module. It works for me, but it has not been extensively tested
in the wild. Handle with care. Report bugs to get them fixed.

=head1 AUTHOR

Thilo Planz, E<lt>planz@epost.deE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Thilo Planz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
