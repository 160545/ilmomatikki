#!/usr/bin/perl -w

# Copyright manti <manti@modeemi.fi> 2009-2018

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
use utf8::all;
use CGI qw/:standard -debug -utf8/;
use CGI::Cookie;
use Crypt::PBKDF2;
use lib ".";
use ilmotexts;
use db;

my $dbh=db::connect_db();

my $showall = url_param('tulijat');
my $done = 0;
my $editdone = 0;
my $kenlie = 0;
my $ok = url_param('ok');
my $eok = url_param('eok');
my $edit = url_param('muokkaa');
my $editcoo = url_param('coomuok');
my $editpw = url_param('mpw');
my $coonames = url_param('coonames');

my $configfile = "config";

my $printdebug=0;

# If limit is over, ilmo is still possible but notice is shown
# Group 1 is limited (Vincit people), 0 for basic, no limit
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
my $log;
my $debuglog;
my @allergies;
my @info;
my @allpw;
my $cookie;

#Password encryption
my $pbkdf2 = Crypt::PBKDF2->new(
    hash_class => 'HMACSHA2',
    hash_args => {
	sha_size => 512,
    },
    salt_len => 10,
    );

#random string for cookie
sub random_string() { 
    my $str = ""; 
    my $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz"; 
    for (my $c = 0; $c < 10; ++$c) { 
	$str .= substr($chars, rand(length($chars)), 1); 
    } 
    return $str; 
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
	} elsif ($line =~ /^log/) {
	    @temparr = split(/\= */,$line);
	    $log = $temparr[1];
	} elsif ($line =~ /^debuglog/) {
	    @temparr = split(/\= */,$line);
	    $debuglog = $temparr[1];
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

sub logging {
    my $time = shift;
    my $msg = shift;
    open(F, ">>", $log);
    print F "$time $msg\n";
    close(F);
}

sub debug {
    my $time = shift;
    my $msg = shift;
    if ($printdebug) {
	open(F, ">>", $debuglog);
	print F "$time $msg\n";
	close(F);
    }
}


# virhekäsittely tehdään eval-lohkon päätteeksi (siellä ilmoitetaan virheet)
eval {
    if (request_method() eq "POST") {
	if (param('poista') && param('name')) {
	    my %cookies = fetch CGI::Cookie;
	    if (param('ncpw')) {
		debug(time(), "pw poisto");
		db::delete_user($dbh,scalar param('ncpw'),undef,scalar param('npeditid'), $pbkdf2);
	    }
	    if ($cookies{'ID'} && param('editid')) {
		debug(time(), "cookie poisto");
		db::delete_user($dbh,undef,$cookies{'ID'}->value,param('editid'), $pbkdf2);
	    }
	    $editpw=0;
	    $editdone = 1;
	    logging(time(), param('name')." poisti ilmoittautumisensa.");
	} elsif (param('kenet') && param('kenetid')) {
	    $kenlie = param('kenetid');
	    my @info = db::select_for_id($dbh, $kenlie);
	    debug(time(), "kenetname if 0->5:".$info[0]->[5]);
	    debug(time(), "kenetname if pbkdf2:".$pbkdf2->generate(''));
	    #	    if ($info[0]->[5] ne $pbkdf2->validate('')) {
	    if ($info[0]->[5] ne '') {
		$edit = 0;
		$editcoo = 0;
		$editpw = 1;
		$coonames = 0;
# handle like there is no cookie, since there is pw
		#$nocookie = 1;
		#$nocookiepw = $info[0]->[5];
		debug(time(), "kenetname if osa");
	    } else {
		debug(time(), "kenetname:".param('kenetname'));
		debug(time(), "kenetname id:".param('kenetid'));
		$edit = 1;
		$editcoo = 1;
		$editpw = 0;
#	    $kenlie = param('kenetname');
		$coonames = 0;
		debug(time(), "kenetname kenliessa:".$kenlie);
		debug(time(), "kenetname edit:".$edit);
		debug(time(), "kenetname editcoo:".$editcoo);
	    }
	} elsif (param('subpw') && param('apw') && param('apwname')) {
	    my $rand;
	    my @cookieandpw = db::select_cookie($dbh, escapeHTML(scalar param('apwname')));
	    for (my $n=0; $n < @cookieandpw; $n++) {
		if ($pbkdf2->validate($cookieandpw[$n]->[1], escapeHTML(scalar param('apw')))) {
		    $rand = $cookieandpw[$n]->[0];
		} else {
		    die "pwcheck";
		}
	    }
	    $cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire,-path=>'url(-absolute=>1)');
	    
#	    if (!$rand[0]->[0]) {
#		die "pwcheck";
#	    }

	    $edit = 1;
	    $editpw = 0;
	    $coonames = 0;
	    $nocookie = 1;
	    $nocookiepw = escapeHTML(scalar param('apw'));
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
	    } elsif (param('privacy') eq 'nicknameinfo') {
		$privacy = 5;
	    } elsif (param('privacy') eq 'nickinfo') {
		$privacy = 4;
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
		$nick = escapeHTML(scalar param('nick'));
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
		push(@allergyvalues, escapeHTML(scalar param('addinfo')));
	    }
	    
	    if (param('ilmoa')) {
#$none means notcoming = 0, coming = 1
		$none="1";
		my $givenpw = "";
		if (length(param('pw'))) {
		    $givenpw = $pbkdf2->generate(escapeHTML(scalar param('pw')))
		}
		my %cookies = fetch CGI::Cookie;
		if ($cookies{'ID'} && db::select_cookie_exists($dbh, $cookies{'ID'}->value)) {
		    db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $givenpw, $grill, $nick, $car, "now", $cookies{'ID'}->value, $none);
		    logging(time(), param('name')." ilmoittautui.");
		} else {
		    my $rand = random_string();
		    $cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire,-path=>'url(-absolute=>1)');    
		    db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $givenpw, $grill, $nick, $car, "now", $rand, $none);
		    logging(time(), param('name')." ilmoittautui.");
		}
		$done = 1;
	    } elsif (param('submuok')) {
		my %cookies = fetch CGI::Cookie;
		if (param('ncpw')) {
		    debug(time(),"ncpw db update npeditid:".param('npeditid'));
		    db::update_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $grill, $nick, $car, $none, undef, scalar param('ncpw'), scalar param('npeditid'), $pbkdf2);
		}
		if ($cookies{'ID'} && param('editid')) {
		    db::update_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $grill, $nick, $car, $none, $cookies{'ID'}->value, undef, scalar(param('editid')), $pbkdf2);
		}
		logging(time(), param('name')." muokkasi ilmoittautumistaan.");
		$editdone = 1;
	    } elsif (param('notcoming')) {
#1= coming, 0=notcoming
                my $givenpw = "";
		if (length(param('pw'))) {
		    $givenpw = $pbkdf2->generate(escapeHTML(scalar param('pw')))
		}		
		my %cookies = fetch CGI::Cookie;
		if ($cookies{'ID'} && db::select_cookie_exists($dbh, $cookies{'ID'}->value)) {
		    db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $givenpw, $grill, $nick, $car, "now", $cookies{'ID'}->value, $none);
		} else {
		    $none = "0";
		    my $rand = random_string();
		    $cookie = new CGI::Cookie(-name=>'ID',-value=>$rand,-expires=>$cookieexpire,-path=>'url(-absolute=>1)');    
		    db::insert_comers($dbh, $ilmolimitgroup, escapeHTML(scalar param('name')), escapeHTML(scalar param('email')), \@allergyvalues, $privacy, $givenpw, $grill, $nick, $car, "now", $rand, $none);
		}
		logging(time(), param('name')." ilmoitti ettei tule.");
		$done = 1;
	    }
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
    } elsif ($@ =~ m/^pwcheck/) {
	$message= itext::pwcheckerror();
    } elsif ($@ =~ m/^raja/) {
	$message= itext::limiterror();
    } else { 
	$message = $@;
    }

    print header("text/html;charset=UTF-8");
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
	$coonames = 0;
	$editpw = 0;
	$edit = 0;
	$url .= "?ok=1";
    }
    if ($editdone) {
#	$nocookie = 0;
	$coonames = 0;
	$editpw = 0;
	$edit = 0;
	$url .= "?eok=1";
    }
    $url .= "?muokkaa=1" if ($edit);
    $url .= "?coomuok=1" if ($editcoo);
    $url .= "?mpw=1" if ($editpw);
    $url .= "?coonames=1" if ($coonames);
    if (!$nocookie && !$kenlie) {
#    if (!$nocookie) {
	debug(time(), "req method nocookie if");
	debug(time(), "req method nocookie url:".$url);
	print redirect(-uri=>$url,-cookie=>$cookie,-status=>303,-nph=>0);
	exit 0;
    }
}

if ($coonames) {
    debug(time(), "if coonames");
    my %cookies = fetch CGI::Cookie;
    @info = db::select_for_cookie($dbh,$cookies{'ID'}->value);
    @allpw = db::select_all_allerg($dbh,$info[0]->[6]);

    debug(time(), "not kenlie:".$kenlie);

    print header("text/html;charset=UTF-8");
    print itext::otsikko();
    print itext::kenmuokata();
    
    for (my $n=0; $n < @info; $n++) { 		
	$kenlie = 1;
	$coonames = 0;
	print $info[$n]->[0];
	print "\n<br>";
	print "<form name=\"kenet\" method=\"post\">";
	print "<input type=\"hidden\" id=\"kenetname\" name=\"kenetname\" value=\"$info[$n]->[0]\">";
	print "<input type=\"hidden\" id=\"kenetid\" name=\"kenetid\" value=\"$info[$n]->[6]\">";
	print itext::formend("kenet",$info[$n]->[0]);
	print "</form>";
    }

    print itext::takaisin();	

} elsif ($showall) {
    print header("text/html;charset=UTF-8");
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
	} elsif ($comers[$n]->[2] == '4') {
	    print itext::namesnick($n, \@comers);
	} elsif ($comers[$n]->[2] == '5') {
	    print itext::namesnickname($n, \@comers);
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
	} elsif ($comers2[$n]->[2] == '4') {
	    print itext::namesnick($n, \@comers2);
	} elsif ($comers2[$n]->[2] == '5') {
	    print itext::namesnickname($n, \@comers2);
	}
	print itext::ilmottu($n, \@comers2);
    }
    print itext::endtable();
    print itext::muokkaa();
    print itext::takaisin();
    print itext::endtags();
} elsif ($ok) {
    print header("text/html;charset=UTF-8");
    print itext::otsikko();
    print itext::done();
    print itext::avecalso();
    print itext::ilmosivu();
    print itext::muokkaa();
    print itext::takaisin();
    print itext::endtags();
} elsif ($eok) {
    print header("text/html;charset=UTF-8");
    print itext::otsikko();
    print itext::edone();
    print itext::ilmosivu();
    print itext::muokkaa();
    print itext::takaisin();
    print itext::endtags();
} elsif ($edit || $editpw) {
    my %cookies = fetch CGI::Cookie;

    if ($nocookie) {
	my @allinfo;
	debug(time(), "nocookie if editissa");
	debug(time(), "nocookie apwname:".param('apwname'));
	debug(time(), "nocookie nocoopw:".$nocookiepw);
	if (!$cookies{'ID'}) {
	    my $cookietime;
	    my @cookieandpw = db::select_cookie($dbh, escapeHTML(scalar param('apwname')));
	    for (my $n=0; $n < @cookieandpw; $n++) {
		if ($cookieandpw[$n]->[1] && $pbkdf2->validate($cookieandpw[$n]->[1], $nocookiepw)) {
		    $cookietime = $cookieandpw[$n]->[0];
		} else {
		    die "pwcheck";
		}
	    }
#	    my @cookie = db::select_cookie($dbh, escapeHTML(scalar param('apwname')),$nocookiepw);
	    debug(time(), "nocookie cookie:".$cookietime);
	    @allinfo = db::select_for_pw($dbh, $cookietime);
	    debug(time(), "allinfo array:".@allinfo);
	    for (my $n=0; $n < @allinfo; $n++) {
		if ($allinfo[$n]->[5] && $pbkdf2->validate($allinfo[$n]->[5], $nocookiepw)) {
		    @info = ($allinfo[$n]);
		} 
	    }
	} else {
	    @allinfo = db::select_for_pw($dbh, $cookies{'ID'}->value);
	    debug(time(), "allinfo array2: $allinfo[0]->[0], $allinfo[1]->[0], $allinfo[2]->[0], $allinfo[3]->[0], $allinfo[4]->[0], $allinfo[5]->[0], $allinfo[6]->[0]");
            for (my $n=0; $n < @allinfo; $n++) {
		debug(time(), "forloop");
		if ($allinfo[$n]->[5] && $pbkdf2->validate($allinfo[$n]->[5], $nocookiepw)) {
		    @info = ($allinfo[$n]);
		    debug(time(), "infoo: @info");
		} 
	    }
	}

	@allpw = db::select_all_allerg($dbh,$info[0]->[6]);
	if ($info[0]->[0] ne ""){
	    $edit = 1;
	} else {
	    $edit = 0;
	}
	$editpw = 0;
    } elsif ($cookies{'ID'} && $kenlie eq "0") {
	my @cookiecounts = db::select_cookie_count($dbh,$cookies{'ID'}->value);
	debug(time(), "cookiecount editissä:".$cookiecounts[0]->[0]);
	debug(time(), "cookie editissä");
	debug(time(), "cookiet:".%cookies);
	debug(time(), "kaikki cookiet ID:".$cookies{'ID'}->value);
	my $cookiecount = $cookiecounts[0]->[0];
	@info = db::select_for_cookie($dbh,$cookies{'ID'}->value);
	@allpw = db::select_all_allerg($dbh,$info[0]->[6]);

#	if ($kenlie eq "0") {
	debug(time(), "redirectin cookiecount kenlie:".$kenlie);
	if ($info[0]->[0] ne "") {
	    if ($cookiecount > 1 && !$editcoo) {
		debug(time(), "redirect tapahtuu");
		my $url = url(-relative=>1);
		$url .= "?coonames=1";
		print redirect(-uri=>$url,-cookie=>$cookie,-status=>303,-nph=>0);
	    }
            $edit = 1;
	} else {
            $edit = 0;
	    $kenlie = 0;
	    debug(time(), "edit nolla else kenlie:".$kenlie);
        }
	$editpw = 0;
    }

    if ($editpw) {
	print header("text/html;charset=UTF-8");
	print itext::otsikko();
	print itext::mheader();
	print itext::kysypw();
    } elsif ($edit || $editcoo) {
	print header("text/html;charset=UTF-8");
	print itext::otsikko();
	print itext::mheader();
	debug(time(), "edit kohta kenlie:".$kenlie);
	if ($editcoo) {
	    @info = db::select_for_id($dbh,$kenlie);
	    @allpw = db::select_all_allerg($dbh,$info[0]->[6]);
	}
	$editcoo = 0;
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
	if ($printnick) {
	    if ($info[0]->[3] == 4) { 
		print itext::formpric("nickinfo", $itext::ohje4);
	    } else {
		print itext::formpri("nickinfo", $itext::ohje4);
	    }
	}
	if ($info[0]->[3] == 3) { 
	    print itext::formpric("allinfo", $itext::ohje1);
	} else {
	    print itext::formpri("allinfo", $itext::ohje1);
	}
	if ($info[0]->[3] == 5) { 
	    print itext::formpric("nicknameinfo", $itext::ohje5);
	} else {
	    print itext::formpri("nicknameinfo", $itext::ohje5);
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

	print "<input type=\"hidden\" id=\"ncpw\" name=\"ncpw\" value=\"$nocookiepw\">";
	print "<input type=\"hidden\" id=\"editid\" name=\"editid\" value=\"$info[0]->[6]\">";
	print "<input type=\"hidden\" id=\"npeditid\" name=\"npeditid\" value=\"$info[0]->[6]\">";
	print "\n<br><br>";
	print itext::formend("submuok",$itext::change);
	print itext::formend("poista",$itext::remove);
    } elsif ($kenlie eq "0") {
	print header("text/html;charset=UTF-8");
	print itext::otsikko();
	print itext::ilmoaensin();
    }
    print itext::takaisin();
    print itext::endtags();
}  else {   
    print header("text/html;charset=UTF-8");
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
    print itext::formpri("nickinfo", $itext::ohje4) if ($printnick);
    print itext::formpri("allinfo", $itext::ohje1);
    print itext::formpri("nicknameinfo", $itext::ohje5);
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
