#########################

use strict;
use Test::More tests => 9;
BEGIN { use_ok('HTML::Manipulator::Document') };

#########################

my ($before, $after, $testname, $data, $obj, $one, $two);


# ===================================

$testname = 'method "replace"';

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


$obj = HTML::Manipulator::Document->from_string($before);

is ( $obj->replace(
	one => $testname
), $after, $testname);

# ===================================

$obj = HTML::Manipulator::Document->from_string($before);
$obj->replace(
	one => $testname
);

is ($obj->as_string(), $after, 'method "as_string"');

# ===================================

$obj = HTML::Manipulator::Document->from_string($after);

is ( $obj->extract_content('one')   
    , $testname
    , 'method "extract_content"');


# ===================================

$testname = 'method "extract"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract( 'link');

ok ( (ref $data 
       and ($data->{href} eq 'link')
       and ( $data->{_content} eq 'link')) 
    , $testname);

# ===================================

$testname = 'method "extract_all_ids"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract_all_ids();


ok ( (ref $data 
       and (delete $data->{link} eq 'a')
        and (delete $data->{one} eq 'div')
         and (delete $data->{two} eq 'div')
          and not keys %$data
       ) 
    , $testname);

# ===================================

$testname = 'method "extract_all_content"';

$obj = HTML::Manipulator::Document->from_string($before);

$data = $obj->extract_all_content();

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

$testname = 'method "from_file" with file handle';

open IN, 't/1.html' or die "could not open t/1.html: $!";
$obj = HTML::Manipulator::Document->from_file(*IN);
close IN;


$data = $obj->extract_all_content();


$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
# ===================================

$testname = 'method "from_file" with file name';

$obj = HTML::Manipulator::Document->from_file('t/1.html');

$data = $obj->extract_all_content();

$two = "\n<a href='link' id=link>link</a><b>text<i>yyy</b>\n";
$one= "\n<div id=two>$two</div>\nblah blah blah\n";

ok ( (ref $data 
       and (delete $data->{link} eq 'link')
       and (delete $data->{one} eq $one)
       and (delete $data->{two} eq $two)
    and not keys %$data
       ) 
    , $testname);
    
    


