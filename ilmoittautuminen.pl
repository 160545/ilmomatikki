#!/usr/bin/perl -w

# Copyright manti <manti@modeemi.fi> 2009

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#    1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above
#    copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided
#    with the distribution.
#    3. The name of the author may not be used to endorse or promote
#    products derived from this software without specific prior
#    written permission.
#     THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
#     EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#     THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
#     PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR
#     BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
#     EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#     TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#     DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#     ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
#     IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
#     THE POSSIBILITY OF SUCH DAMAGE.



use strict;
use CGI qw/:standard -debug/;
use POSIX qw(strftime);
use ilmotexts;
use db;

my $dbh=db::connect_db();

# virhek‰sittely tehd‰‰n eval-lohkon p‰‰tteeksi (diell‰ ilmoitetaan virheet)
eval {
    if (param('ilmoa') && param('name') && param('email')) {
	my @value;
	my @values;
	@value = grep {/^[0-9]+$/} param();

	my @items = itext::allergy();	

	foreach my $item (@value) {
	    push(@values, $items[$item]);
	}
	
	push(@values, escapeHTML(param('addinfo')));
	my $commavalues = join(', ', sort(@values));

 	db::insert_comers($dbh, escapeHTML(param('name')), escapeHTML(param('email')), $commavalues);
    }

#     # Add checked stuff from memory to shopping list, if first
#     # character is @, add the content of memory file
#     if (param('addtoo')) {

# 	kauppa::add_from_memory($dbh, \@value, $olist);
#     }
};

# if ($@) {
#     my $message;

#     if ($@ =~ m/^merkki/) {
# 	$message="Voivoi, sallitut merkit ovat: a-zA-Z0-9.ˆ‰÷ƒ?/ - Yrit‰ uudelleen";
#     } else { 
# 	$message = $@;
#     }

#     print header;
#     print <<END;
#     <html><head><title>ihtml::$title</title></head><body>
#     END
#     print"Arrgh: $message";
#     print"</body></html>";
#     exit 0;
#}

#if (!$updown && !$remove && request_method() eq "POST") {
#    my $url = url(-relative=>1);
#    $url .= "?group=$group" if ($group);
#    print redirect(-uri=>$url,-status=>303,-nph=>0);
#    exit 0;
#}

my @values = itext::allergy();

print header;

print "<html><head><title>".itext::title()."</title></head><body>";

print"<h1>".itext::header()."</h1>";

print"<form name=\"ilmottaudu\" method=\"post\">";
print itext::name();
print"<input type=\"text\" name=\"name\" size=30><br>\n";
print itext::email();
print"<input type=\"text\" name=\"email\" size=30><br>\n";
print itext::allerg();
for (my $n=0; $n < @values; $n++) { 
    print"<br><input type=\"checkbox\" name=\"".$n."\">$values[$n]\n";
}
print"<input type=\"text\" name=\"addinfo\" size=30><br>\n";
print"<br><input type=\"submit\" name=\"ilmoa\" value=\"".itext::ilmotext()."\">\n";
print "</body></html>";
