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
use ilmotexts;
use db;

my $dbh=db::connect_db();

my $showall = url_param('tulijat');
my $done = 0;
my $ok = url_param('ok');

# virhekäsittely tehdään eval-lohkon päätteeksi (diellä ilmoitetaan virheet)
eval {
    if (param('ilmoa') && param('name')) {

#	die "email" if !(param('email'));
	die "merkki" if !(param('name') =~ /^[a-zA-Z.åöäÅÖÄ, -]*?$/);
	die "merkki" if !(param('email') =~ /(^[^\@]+\@[^\@]+$)?/);
	die "merkki" if !(param('email') =~ /(^[a-zA-Z0-9.åöäÅÖÄ, -\+\-:\@]*?$)?/);
	
	my @values;
	my $privacy;
	my $grill;
	my @value = grep {/^[0-9]+$/} param();
	my @items = itext::allergy();	
	
	if (param('privacy') eq 'allinfo') {
	    $privacy = 3;
	} elsif (param('privacy') eq 'nameinfo') {
	    $privacy = 2;
	} elsif (param('privacy') eq 'noinfo') {
	    $privacy = 1;
	} else {
	    $privacy = 3;
	}

	if (param('grilling') eq 'nogrill') {
	    $grill = 1;
	} elsif (param('grilling') eq 'maybegrill') {
	    $grill = 2;
	} elsif (param('grilling') eq 'yesgrill') {
	    $grill = 3;
	} else {
	    $grill = 4;
	}
	
	foreach my $item (@value) {
	    push(@values, $items[$item]);
	}
	
	push(@values, escapeHTML(param('addinfo')));

	my $commavalues = join(', ', sort(@values));
#	my $fragment =~ s/^, //;
 	db::insert_comers($dbh, escapeHTML(param('name')), escapeHTML(param('email')), $commavalues, $privacy, $grill, "now");
	
	$done = 1;
    }
};

if ($@) {
    my $message;
    
    if ($@ =~ m/^merkki/) {
	$message= itext::charerror();
#    } elsif ($@ =~ m/^email/) {
#	$message= itext::emailerror();
    } else { 
	$message = $@;
    }
    
    print header;
    print itext::otsikko();
    print"$message";
    print itext::endtags();
    exit 0;
}

if (request_method() eq "POST") {
    my $url = url(-relative=>1);
    $url .= "?tulijat=1" if ($showall);
    $url .= "?ok=1" if ($done);
    print redirect(-uri=>$url,-status=>303,-nph=>0);
    exit 0;
}

if ($showall) {
    print header;
    print itext::otsikko();
    print itext::tulossa();
    print itext::starttable();
    my @comers = db::select_names($dbh);
    for (my $n=0; $n < @comers; $n++) { 
	if ($comers[$n]->[2] == '3') {
	    print itext::namesemail($n, \@comers);
	} elsif ($comers[$n]->[2] == '2') {
	    print itext::names($n, \@comers);
	} elsif ($comers[$n]->[2] == '1') {
	    print itext::namesnone();
	}
	print itext::ilmottu($n, \@comers);
    }
    print itext::endtable();
    print itext::takaisin();
    print itext::endtags();
} elsif ($ok) {
    print header;
    print itext::otsikko();
    print itext::done();
    print itext::ilmosivu();
    print itext::takaisin();
    print itext::endtags();
}  else {   
    my @values = itext::allergy();
    
    print header;
    print itext::otsikko();
    print itext::headeri();
    print itext::formi1();
    
    for (my $n=0; $n < @values; $n++) { 
	print itext::boxes($n);
    }
    
    print itext::formi2();
    
    print itext::ilmosivu();
    print itext::endtags();
}
