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
use CGI::Cookie;
use Digest::MD5 qw(md5_hex);
use ilmotexts;
use db;

my $dbh=db::connect_db();

my $showall = url_param('tulijat');
my $done = 0;
my $ok = url_param('ok');
my $edit = url_param('muokkaa');
my $editpw = url_param('mpw');

my $configfile = "config";

my $printgrill = 0;
my $printnick = 0;
my $cookieexpire;
my @allergies;
my @info;
my @allpw;
my $cookie;

#random string for cookie
sub random_string() { 
    my $str = ""; 
    my $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"; 
    for (my $c = 0; $c < 10; ++$c) { 
	$str .= substr($chars, rand(length($chars)), 1); 
    } 
    return $str; 
}

#read allergies from config file:
if (open(F, "<", $configfile)) {
    my @temparr;
    my $line;
    while ($line = <F>) {
        chomp $line;
	if ($line =~ /^allergies/) {
	    @temparr = split(/\= */,$line);
	    @allergies = split(/,/,$temparr[1]);
	} elsif ($line =~ /^nick/) {
	    @temparr = split(/\= */,$line);
	    $printnick = $temparr[1];
	} elsif ($line =~ /^grill/) {
	    @temparr = split(/\= */,$line);
	    $printgrill = $temparr[1];
     	} elsif ($line =~ /^expire/) {
	    @temparr = split(/\= */,$line);
	    $cookieexpire = $temparr[1];
	}
    }
}
close (F);

# virhekäsittely tehdään eval-lohkon päätteeksi (diellä ilmoitetaan virheet)
eval {
    if (param('subpw') && param('apw')) {
	my @rand = db::select_cookie($dbh, param('apwname'), md5_hex(escapeHTML(param('apw'))));
	$cookie = new CGI::Cookie(-name=>'ID',-value=>$rand[0]->[0],-expires=>$cookieexpire);

	$edit = 1;
	$editpw = 0;
    }

    if (param('ilmoa') && param('name')) {

#	die "email" if !(param('email'));
	die "merkki" if !(param('name') =~ /^[a-zA-Z.åöäÅÖÄ, -]*?$/);
	if (!defined(param('email'))) {
	    die "merkki" if !(param('email') =~ /(^[^\@]+\@[^\@]+$)?/);
	    die "merkki" if !(param('email') =~ /(^[a-zA-Z0-9.åöäÅÖÄ, -\+\-:\@]*?$)?/);
	}	

	my @allergyvalues;
	my $privacy;
	my $grill;
	my $nick;
	my @value = grep {/^[0-9]+$/} param();
	
	if (!defined(param('privacy'))) {
	    $privacy = 2;
	} elsif (param('privacy') eq 'allinfo') {
	    $privacy = 3;
	} elsif (param('privacy') eq 'nameinfo') {
	    $privacy = 2;
	} elsif (param('privacy') eq 'noinfo') {
	    $privacy = 1;
	} else {
	    $privacy = 2;
	}

	if ($printgrill) {
	    if (!defined(param('grilling'))) {
		$grill = 4;
	    } elsif (param('grilling') eq 'nogrill') {
		$grill = 1;
	    } elsif (param('grilling') eq 'maybegrill') {
		$grill = 2;
	    } elsif (param('grilling') eq 'yesgrill') {
		$grill = 3;
	    } else {
		$grill = 4;
	    }
	} else {
	    $grill = 0;
	}

	if ($printnick) {
	    $nick = escapeHTML(param('nick'));
	} else {
	    $nick = "undef";
	}
	
	foreach my $item (@value) {
	    push(@allergyvalues, $allergies[$item]);
	}

	if (param('addinfo')) {
	    push(@allergyvalues, escapeHTML(param('addinfo')));
	}

	my $rand = random_string();
	$cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire);


 	db::insert_comers($dbh, escapeHTML(param('name')), escapeHTML(param('email')), \@allergyvalues, $privacy, md5_hex(escapeHTML(param('pw'))), $grill, $nick, "now", $rand);
	
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
    $url .= "?muokkaa=1" if ($edit);
    $url .= "?mpw=1" if ($editpw);
    print redirect(-uri=>$url,-cookie=>$cookie,-status=>303,-nph=>0);
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
    print itext::muokkaa();
    print itext::takaisin();
    print itext::endtags();
} elsif ($ok) {
    print header;
    print itext::otsikko();
    print itext::done();
    print itext::ilmosivu();
    print itext::muokkaa();
    print itext::takaisin();
    print itext::endtags();
} elsif ($edit || $editpw) {
    print header;
    my %cookies = fetch CGI::Cookie;

    if ($cookies{'ID'}) {
	@info = db::select_for_cookie($dbh,$cookies{'ID'}->value);
	@allpw = db::select_all_allerg($dbh,$info[0]->[6]);

	$edit = 1;
	$editpw = 0;
    }

    print itext::otsikko();
    print itext::mheader();
    if ($editpw) {
	print itext::kysypw();
    } elsif ($edit) {

	print itext::formi1alku("muokkaus", \@info);	
	print itext::formi1nick(\@info) if ($printnick);
	
	if ($printgrill){
	    print itext::formi1grill1();
	    if ($info[0]->[4] == 1) { 
		print itext::formi1grill2c("nogrill", $itext::grill1);
	    } else {
		print itext::formi1grill2("nogrill", $itext::grill1);
	    }
	    if ($info[0]->[4] == 2) { 
		print itext::formi1grill2c("maybegrill", $itext::grill2);
	    } else {
		print itext::formi1grill2("maybegrill", $itext::grill2);
	    }
	    if ($info[0]->[4] == 3) { 
		print itext::formi1grill2c("yesgrill", $itext::grill3);
	    } else {
		print itext::formi1grill2("yesgrill", $itext::grill3);
	    }
	    print itext::formi1grill3();
	}

	my $lastitem = $allpw[-1];
	my $addfield = 1;
	for (my $n=0; $n < @allergies; $n++) {	
	    my $printornot = 1;
	    for (my $m=0; $m < @allpw; $m++) {	
		if ($allergies[$n] eq $allpw[$m]->[0]) {
		    print itext::boxescheck($n, \@allergies);
		    $printornot = 0;
		}
	    }
	    if ($printornot) {
		print itext::boxes($n, \@allergies);
	    }
	    if (defined($lastitem->[0])) {
		if ($lastitem->[0] eq $allergies[$n]) {
		    $addfield = 0
		}
	    }
	}
	if ($addfield) {
	    print itext::addfield($lastitem->[0]);
	}
	print itext::formpria();
	if ($info[0]->[3] == 1) { 
	    print itext::formpric("noinfo", $itext::ohje3);
	} else {
	    print itext::formpri("noinfo", $itext::ohje3);
	}
	if ($info[0]->[3] == 2) { 
	    print itext::formpric("nameinfo", $itext::ohje2);
	} else {
	    print itext::formpri("nameinfo", $itext::ohje2);
	}
	if ($info[0]->[3] == 3) { 
	    print itext::formpric("allinfo", $itext::ohje1);
	} else {
	    print itext::formpri("allinfo", $itext::ohje1);
	}	    
	
	print itext::formend("submuok",$itext::change);
#tähän väliin kysy salasanaa, tulosta sitten oikeat infot ruudulle, ja talleta muokatut tiedot kantaan
    }
    print itext::takaisin();
    print itext::endtags();
}  else {   
    print header;
    print itext::otsikko();
    print itext::headeri();
    print itext::formi1alku("ilmoittaudu");

    print itext::formi1nick() if ($printnick);

    if ($printgrill){
	print itext::formi1grill1();
	print itext::formi1grill2("nogrill", $itext::grill1);
	print itext::formi1grill2("maybegrill", $itext::grill2);
	print itext::formi1grill2("yesgrill", $itext::grill3);
	print itext::formi1grill3();
    }

    print itext::allerg();
    for (my $n=0; $n < @allergies; $n++) { 
	print itext::boxes($n, \@allergies);
    }

    print itext::addfield();
    print itext::formpria();
    print itext::formpri("noinfo", $itext::ohje3);
    print itext::formpri("nameinfo", $itext::ohje2);
    print itext::formpri("allinfo", $itext::ohje1);
    print itext::formend("ilmoa",$itext::ilmotext);

    print itext::ilmosivu();
    print itext::endtags();
}
