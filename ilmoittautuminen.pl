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

my $ilmolimit = $ENV{ILMOLIMIT};
my $ilmolimitgroup = $ENV{ILMOLIMITGROUP};

my $printgrill = 0;
my $printnick = 0;
my $printnocome = 0;
my $printcar = 0;
my $printgrillp = 0;
my $printallergies = 0;
my $nocookie = 0;
my $none = 0;
my $nocookiepw = "";
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

sub logging {
    my $time = shift;
    my $msg = shift;
#    open(F, ">>", "/home/manti/public_html/ilmodev/ilmo.log");
    open(F, ">>", "/home/manti/public_html/ilmo/ilmo.log");
    print F "$time $msg\n";
    close(F);
}

#read allergies and all other stuff from config file:
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
	} elsif ($line =~ /^praller/) {
            @temparr = split(/\= */,$line);
            $printallergies = $temparr[1];
     	} elsif ($line =~ /^expire/) {
	    @temparr = split(/\= */,$line);
	    $cookieexpire = $temparr[1];
	} elsif ($line =~ /^nocome/) {
            @temparr = split(/\= */,$line);
            $printnocome = $temparr[1];
	} elsif ($line =~ /^car/) {
            @temparr = split(/\= */,$line);
            $printcar = $temparr[1];
	} elsif ($line =~ /^grpercent/) {
            @temparr = split(/\= */,$line);
            $printgrillp = $temparr[1];
	}
    }
}
close (F);

# virhekäsittely tehdään eval-lohkon päätteeksi (diellä ilmoitetaan virheet)
eval {
    if (request_method() eq "POST") {
	if (param('poista') && param('name')) {
	    my %cookies = fetch CGI::Cookie;
	    if (param('ncpw')) {
		(db::delete_user($dbh,param('ncpw')),undef);
	    }
	    if ($cookies{'ID'}) {
		(db::delete_user($dbh,undef,$cookies{'ID'}->value));
	    }
	    $editpw=0;
	    logging(time(), param('name')." poisti ilmoittautumisensa.");
	} elsif (param('subpw') && param('apw') && param('apwname')) {
	    my @rand = db::select_cookie($dbh, param('apwname'), md5_hex(escapeHTML(param('apw'))));
	    $cookie = new CGI::Cookie(-name=>'ID',-value=>$rand[0]->[0],-expires=>$cookieexpire,-path=>'url(-absolute=>1)');
	    
	    $edit = 1;
	    $editpw = 0;
	    $nocookie = 1;
	    $nocookiepw = md5_hex(escapeHTML(param('apw')));
	} elsif ((param('ilmoa') || param('submuok') || param('notcoming')) && param('name')) {

	    die "merkki" if !(param('name') =~ /^[a-zA-Z.åöäÅÖÄ, -]*?$/);
	    
	    my @allergyvalues;
	    my $privacy;
	    my $grill;
	    my $car;
	    my $nick;
	    my @value = grep {/^[0-9]+$/} param();

	    if (!defined($ilmolimit)) {
		# no limit
		$ilmolimit = 10000;
	    }

	    if (!defined($ilmolimitgroup)) {
		# default group
		$ilmolimitgroup = 0;
	    }
	    
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

	    if ($printcar) {
		if (!defined(param('car'))) {
		    $car = "2";
		} elsif (param('car') eq 'yescar') {
		    $car = "1";
		} elsif (param('car') eq 'nocar') {
		    $car = "0";
		}
	    } else {
		$car = "2";
	    }
	    
	    if ($printnick) {
		$nick = escapeHTML(param('nick'));
	    } else {
		$nick = "undef";
	    }

#1= coming, 0=notcoming
	    if ($printnocome) {
		if (param('coming')) {
		    $none = "1";	
		}
	    } else {
		$none = "undef";
	    }
	    
	    foreach my $item (@value) {
		push(@allergyvalues, $allergies[$item]);
	    }
	    
	    if (param('addinfo')) {
		push(@allergyvalues, escapeHTML(param('addinfo')));
	    }
	    
	    if (param('ilmoa')) {
		$none="1";
		my $rand = random_string();
		$cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire,-path=>'url(-absolute=>1)');    
		db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(param('name')), escapeHTML(param('email')), \@allergyvalues, $privacy, md5_hex(escapeHTML(param('pw'))), $grill, $nick, $car, "now", $rand, $none);
		logging(time(), param('name')." ilmoittautui.");
	    } elsif (param('submuok')) {
		my %cookies = fetch CGI::Cookie;
		if (param('ncpw')) {
		    db::update_comers($dbh, $ilmolimitgroup, escapeHTML(param('name')), escapeHTML(param('email')), \@allergyvalues, $privacy, $grill, $nick, $car,  $none, undef,param('ncpw'));
		}
		if ($cookies{'ID'}) {
		    db::update_comers($dbh, $ilmolimitgroup, escapeHTML(param('name')), escapeHTML(param('email')), \@allergyvalues, $privacy, $grill, $nick, $car, $none, $cookies{'ID'}->value, undef);
		}
		logging(time(), param('name')." muokkasi ilmoittautumistaan.");
	    } elsif (param('notcoming')) {
#1= coming, 0=notcoming
		$none = "0";
		my $rand = random_string();
		$cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire,-path=>'url(-absolute=>1)');    
		db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(param('name')), escapeHTML(param('email')), \@allergyvalues, $privacy, md5_hex(escapeHTML(param('pw'))), $grill, $nick, $car, "now", $rand, $none);
		logging(time(), param('name')." ilmoitti ettei tule.");
	    }
	    $done = 1;
	} else {
	    die "nimi";
	}
    }
};

if ($@) {
    my $message;
    
    if ($@ =~ m/^merkki/) {
	$message= itext::charerror();
    } elsif ($@ =~ m/^nimi/) {
	$message= itext::nameerror();
    } elsif ($@ =~ m/^raja/) {
	$message= itext::limiterror();
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
    if ($done) {
#	$nocookie = 0;
	$url .= "?ok=1";
    }
    $url .= "?muokkaa=1" if ($edit);
    $url .= "?mpw=1" if ($editpw);
    if (!$nocookie) {
	print redirect(-uri=>$url,-cookie=>$cookie,-status=>303,-nph=>0);
	exit 0;
    }
}

if ($showall) {
    print header;
    print itext::otsikko();
    print itext::tulossa();
    print itext::starttable();
    my @comers = db::select_names($dbh,"1");
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

    if($printgrill && $printgrillp) {
	my @hotgrillers = db::count_grill_percent($dbh,"3");
	my @maybegrillers = db::count_grill_percent($dbh,"2");
	print itext::grillp(\@hotgrillers, \@maybegrillers);
    }

    print itext::nottulossa();
    print itext::starttable();
    my @comers2 = db::select_names($dbh,"0");
    for (my $n=0; $n < @comers2; $n++) { 
	if ($comers2[$n]->[2] == '3') {
	    print itext::namesemail($n, \@comers2);
	} elsif ($comers2[$n]->[2] == '2') {
	    print itext::names($n, \@comers2);
	} elsif ($comers2[$n]->[2] == '1') {
	    print itext::namesnone();
	}
	print itext::ilmottu($n, \@comers2);
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

    if ($nocookie) {
	@info = db::select_for_pw($dbh, $nocookiepw, $cookie->value);
	@allpw = db::select_all_allerg($dbh,$info[0]->[6]);
	
	if ($info[0]->[0] ne ""){
	    $edit = 1;
	} else {
	    $edit = 0;
	}
	$editpw = 0;
    } elsif ($cookies{'ID'}) {
	@info = db::select_for_cookie($dbh,$cookies{'ID'}->value);
	@allpw = db::select_all_allerg($dbh,$info[0]->[6]);

	if ($info[0]->[0] ne ""){
	    $edit = 1;
	} else {
            $edit = 0;
        }
	$editpw = 0;
    }

    print itext::otsikko();
    print itext::mheader();
    if ($editpw) {
	print itext::kysypw();
    } elsif ($edit) {
	if (defined($ilmolimitgroup)) {
	    my @c = db::select_igroup_count($dbh, "1", $ilmolimitgroup);
	    if ($c[0]->[0] >= $ilmolimit) {
		print itext::limitover(($c[0]->[0]-$ilmolimit));
	    } else {
		print itext::limitleft(($ilmolimit-$c[0]->[0]));
	    }
	}
	
	print itext::formi1alku("muokkaus", \@info);	
	print itext::formi1nick(\@info) if ($printnick);
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

	if ($printallergies) {
	    print itext::allerg();
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
	}

	if ($printcar) {
	    print itext::formcartext();
	    if ($info[0]->[9] == 1) {
		print itext::formcarc("yescar", $itext::yescar);
	    } else {
		print itext::formcar("yescar", $itext::yescar);
	    }
	    if ($info[0]->[9] == 0) {
		print itext::formcarc("nocar", $itext::nocar);
	    } else {
		print itext::formcar("nocar", $itext::nocar);
	    }
	    print itext::formi1grill3();
	}

	if ($printnocome) {
#1= coming, 0=notcoming, goes to if when 1
	    if ($info[0]->[8]) {
		print itext::checknocomec("coming",$itext::coming2);
	    } else {
		print itext::formwasnotcoming();
		print itext::checknocome("coming",$itext::coming1);
	    }
	}	

	print "<input type=\"hidden\" id=\"ncpw\" name=\"ncpw\" value=$nocookiepw>";
	print "\n<br><br>";
	print itext::formend("submuok",$itext::change);
	print itext::formend("poista",$itext::remove);
    } else {
	print itext::ilmoaensin();
    }
    print itext::takaisin();
    print itext::endtags();
}  else {   
    print header;
    print itext::otsikko();
    print itext::headeri();

    if (defined($ilmolimitgroup)) {
	my @c = db::select_igroup_count($dbh, "1", $ilmolimitgroup);
	if ($c[0]->[0] >= $ilmolimit) {
	    print itext::limitover(($c[0]->[0]-$ilmolimit));
	} else {
	    print itext::limitleft(($ilmolimit-$c[0]->[0]));
	}
    }

    print itext::formi1alku("ilmoittaudu");
    print itext::formi1nick() if ($printnick);
    print itext::formpria();
    print itext::formpri("noinfo", $itext::ohje3);
    print itext::formpri("nameinfo", $itext::ohje2);
    print itext::formpri("allinfo", $itext::ohje1);
    print "<br><br>";

    print itext::formresttext();

    if ($printgrill){
	print itext::formi1grill1();
	print itext::formi1grill2("nogrill", $itext::grill1);
	print itext::formi1grill2("maybegrill", $itext::grill2);
	print itext::formi1grill2("yesgrill", $itext::grill3);
	print itext::formi1grill3();
    }

    if ($printallergies) {
	print itext::allerg();
	for (my $n=0; $n < @allergies; $n++) { 
	    print itext::boxes($n, \@allergies);
	}
	
	print itext::addfield();
    }
    
    if ($printcar){
	print itext::formcartext();
	print itext::formcar("yescar", $itext::yescar);
	print itext::formcar("nocar", $itext::nocar);
	print itext::formi1grill3();
    }

    print itext::formpw();
    print itext::formend("ilmoa",$itext::ilmotext);
    if ($printnocome) {
	print itext::nocometextalku();
	print itext::formend("notcoming",$itext::nocome);
    }

    print itext::ilmosivu();
    print itext::endtags();
}
