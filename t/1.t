# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;
use Test::More tests => 15;
BEGIN { use_ok('HTML::Manipulator') };

#########################

my ($before, $after, $testname, $data, $one, $two, $link);


# ===================================

$testname = 'replace a simple div without nested tags';

$before = <<HTML;
<html>
<body>
<div id=simple>
XXXXXXX
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace($before, 
    simple => $testname
), $after, $testname);

# ===================================

$testname = 'replace a div with nested tags (but no divs) and uppercase tags';

$before = <<HTML;
<html>
<body>
<div id=simple>
<a href='link'>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace( uc $before, 
    SIMPLE =>  uc $testname
),  uc $after, $testname);

# ===================================

$testname = 'replace a link href and text';

$before = <<HTML;
<html>
<body>
<div id=simple>
<a Href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=simple>
<a href='new href' id='link'>$testname</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML
#also checking some case sensitivity issues here
is ( HTML::Manipulator::replace($before, 
    link => { HREF => 'new href', _content => $testname}
), $after, $testname);

# ===================================

$testname = 'replace two divs and a nested link';

$before = <<HTML;
<html>
<body>
<div id=one>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=one>$testname</div>
<div id=two>$testname$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace($before, 
    link => { href => 'new href', _content => $testname},
    one => $testname,
    two => $testname.$testname
), $after, $testname);

# ===================================

$testname = 'replace a div with a nested div';

$before = <<HTML;
<html>
<body>
<div id=one>
<div id=two>
<a href='link' id=link>link</a><b>text<i>yyy</b>
</div>
blah blah blah
</div>
</body>
</html>
HTML

$after = <<HTML;
<html>
<body>
<div id=one>$testname</div>
</body>
</html>
HTML

is ( HTML::Manipulator::replace($before, 
    link => { href => 'new href', _content => $testname},
    one => $testname,
    two => $testname.$testname
), $after, $testname);


# ===================================


is ( HTML::Manipulator::extract_content($after, 'one')   
    , $testname
    , 'extract a div content');


# ===================================

$testname = 'extract a link with attributes';

$data = HTML::Manipulator::extract($before, 'link');

ok ( (ref $data 
       and ($data->{href} eq 'link')
       and ( $data->{_content} eq 'link')) 
    , $testname);

# ===================================

$testname = 'extract all element IDs';

$data = HTML::Manipulator::extract_all_ids($before);


ok ( (ref $data 
       and (delete $data->{link} eq 'a')
        and (delete $data->{one} eq 'div')
         and (delete $data->{two} eq 'div')
          and not keys %$data
       ) 
    , $testname);

# ===================================

$testname = 'extract the content of all IDs';

$data = HTML::Manipulator::extract_all_content($before);

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

#is( delete ($data->{link}) , 'link', $testname);
#is( delete ($data->{two}) , $two, $testname);
#is( delete ($data->{one}) , $one, $testname);

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
# ===================================

$testname = 'extract contents from HTML without IDs';

$data = HTML::Manipulator::extract_all('not really HTML');

is (keys %$data, 0, $testname);
    
# ===================================

$testname = 'extract the content of all IDs from a file';

open IN, 't/1.html' or die "could not open t/1.html: $!";
$data = HTML::Manipulator::extract_all_content(*IN);
close IN;

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

#is( delete ($data->{link}) , 'link', $testname);
#is( delete ($data->{two}) , $two, $testname);
#is( delete ($data->{one}) , $one, $testname);

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
    

# ===================================

$testname = 'handle quotation marks in attributes';

$before = <<HTML;
<a href='link' id=link>link</a><b>text<i>yyy</b>
HTML

$after = <<HTML;
<a href="new 'href" id='link'>$testname</a><b>text<i>yyy</b>
HTML

is ( HTML::Manipulator::replace($before, 
    link => { href => "new 'href", _content => $testname}
), $after, $testname);

# ===================================

$testname = 'extract the document title';

$before = <<HTML;
<title>$testname</title>
HTML


is ( HTML::Manipulator::extract_title($before), $testname, $testname);

# ===================================

$testname = 'replace the document title';

$after = <<HTML;
<title>$testname</title>
HTML

is ( HTML::Manipulator::replace_title($before, $testname),
	$after, $testname);
	




