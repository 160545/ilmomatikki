#!/usr/bin/perl -w

# Copyright manti <manti@modeemi.fi> 2009-2015

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
use Encode qw(decode encode);
use ilmotexts;
use db;

my $dbh=db::connect_db();

my @comers = db::select_all_part($dbh);
my @allergs;
my @allergyheaders;
my $udallergy = "";
my $configfile = "config";

#read allergies from config file:
if (open(F, "<", $configfile)) {
    my @temparr;
    my $line;
    while ($line = <F>) {
        chomp $line;
        if ($line =~ /^allergies/) {
            @temparr = split(/\= */,$line);
            @allergyheaders = split(/,/,$temparr[1]);
        }
    }
}
close (F);

# virhek‰sittely tehd‰‰n eval-lohkon p‰‰tteeksi (diell‰ ilmoitetaan virheet)
eval {
    if (param('export')) {
	my $csvfile = "ilmo.csv";

	local *FCSV;
	open(FCSV, ">>", $csvfile) or die "Ei voi avata $csvfile";

#each allergy is a header, 1 means checked, 0 no
	print FCSV "Id,Nimi,Email,Nick,Privacy,Grill,Car yes(1)/no(0),Tulossa(1)/Ei(0),Submitted,Group";
	for (my $n=0; $n < @allergyheaders; $n++) {
	    print FCSV ",".$allergyheaders[$n];
	}
	print FCSV ",Other\n";

# 0== ei parkkitilaa/kommenttia siihen 1== parkkitilaa, 0 == ei tule, 1== tulee
	@comers = db::select_all_part($dbh);
	
	for (my $n=0; $n < @comers; $n++) {
	    print FCSV $comers[$n]->[6];
	    print FCSV ",".$comers[$n]->[0];
	    print FCSV ",".$comers[$n]->[1];
	    print FCSV ",".$comers[$n]->[2];

	    if ($comers[$n]->[3] == '1') {
		print FCSV ",ei n‰ytet‰ mit‰‰n";
	    } elsif ($comers[$n]->[3] == '2') {
		print FCSV ",n‰ytet‰‰n vain nimi";
	    } elsif ($comers[$n]->[3] == '3') {
		print FCSV ",n‰ytet‰‰n nimi ja email";
	    } elsif ($comers[$n]->[3] == '4') {
		print FCSV ",n‰ytet‰‰n nick";
	    } elsif ($comers[$n]->[3] == '5') {
		print FCSV ",n‰ytet‰‰n nimi ja nick";
	    } 
	    if ($comers[$n]->[4] == '1') {
		print FCSV ",En ajatellut grillata";
	    } elsif ($comers[$n]->[4] == '2') {
		print FCSV ",Saatanpa grillatakin";
	    } elsif ($comers[$n]->[4] == '3') {
		print FCSV ",Grilli kuumaksi";
	    } elsif ($comers[$n]->[4] == '4') {
		print FCSV ",Ei mielipidett‰ grillaukseen";
	    } elsif ($comers[$n]->[4] == '0') {
		print ",";
	    } 
	    if ($comers[$n]->[8] == '1') {
		print FCSV ",1";
	    } elsif ($comers[$n]->[8] == '0' || $comers[$n]->[8] == '2') {
		print FCSV ",0";
	    } 
	    print FCSV ",".$comers[$n]->[7];
	    print FCSV ",".$comers[$n]->[5];
	    print FCSV ",".$comers[$n]->[9];

	    my $found = 0;
	    if ($comers[$n]->[6]) {
		@allergs = db::select_all_allerg($dbh, $comers[$n]->[6],$udallergy);
		for (my $o=0; $o < @allergyheaders; $o++) {
		    for (my $l=0; $l < @allergs; $l++) {
			if ($allergyheaders[$o] eq $allergs[$l]->[0]) {
			    $found = 1;
			} 
		    }
		    if ($found == '1') {
			print FCSV ",1";
		    } else {
			print FCSV ",0";
		    }
		    $found = 0;
		}
	    }
	    for my $i (@allergs) {
		if (!grep {$i->[0] eq $_} @allergyheaders) {
		    print FCSV ",".$i->[0];
		}
	    }
	    print FCSV "\n";
	}
	close(FCSV);
    }

    if (param('up')) {
#descending order
	my $updown = "1";
	if (param('sort') ne "Allergies") {
	    @comers = db::select_all_part($dbh,param('sort'),$updown);
	} else {
	    $udallergy = "all_up_desc";
	}
    }

    if (param('down')) {
#ascending order
	my $updown = "0";
	if (param('sort') ne "Allergies") {
	    @comers = db::select_all_part($dbh,param('sort'),$updown);
	} else {
	    $udallergy = "all_down_asc";
	}
    }

    if (param('poista')) {
	my @values;
	my @value = grep {/^[0-9]+$/} param();
	my @items = db::select_all_part($dbh);

	foreach my $item (@value) {
	    push(@values, $items[$item]);
	}

	for (my $n=0; $n < @values; $n++) {
	    db::delete_record($dbh, $values[$n]->[0], $values[$n]->[5]);
	}
    }

    if (param('adack')) {
	my @values;
	my @value = grep {/^[0-9A-Za-z]+$/} param();

	foreach my $item (@value) {
#	for (my $n=0; $n < @values; $n++) {
	    db::admin_ack_email($dbh, $item);
	}
    }

};

 if ($@) {
     my $message;

     if ($@ =~ m/^merkki/) {
	 $message= itext::charerror();
     } elsif ($@ =~ m/^email/) {
	 $message= itext::emailerror()
     } else { 
	 $message = $@;
     }

     print header;
     print itext::otsikko();
     print"$message";
     print itext::endtags();
     exit 0;
}

print header;
print "<html><head><title>Ilmoittautumisen hallintasivu</title></head><body>";
print "<h1>Email ack puuttuu:</h1>";

my @noack=db::select_no_ack($dbh);

#print "<table border=1>\n";
print "<table>\n";
print "<th></th>";
print "<form name=\"adminack\" method=\"post\">";

for (my $a=0; $a < @noack; $a++) { 
    my $name2 = Encode::decode_utf8($noack[$a]->[0]);
    my $name = escapeHTML($name2);
    print "<tr><td><input type=\"checkbox\" id=\"$noack[$a]->[1]\" name=\"$noack[$a]->[1]\"></td>";
    print "<td>$name</td><td></tr>\n";

}

print "</table><br><input type=\"submit\" name=\"adack\" value=\"Ack\"></form>\n";

print "<br>";

print "<h1>Tulijat:</h1>";
print "<table border=1>\n";
print "<th></th>";

for (my $n=0; $n < @itext::headers; $n++) { 
    print "<form name=\"adminsort\" method=\"get\">";
    print "<th><input type=\"hidden\" id=\"sort\" name=\"sort\" value=\"$itext::headers[$n]\">$itext::headers[$n] ";
    print "<input type=\"submit\" name=\"up\" value=\"&uarr;\">";
    print "<input type=\"submit\" name=\"down\" value=\"&darr;\"></th>\n";
    print "</form>";
}

print "<form name=\"adminilmo\"method=\"post\">";
for (my $n=0; $n < @comers; $n++) { 
    if ($comers[$n]->[7]) {
	print "<tr><td><input type=\"checkbox\" id=\"$n\" name=\"$n\"></td><td>$comers[$n]->[0]</td><td>$comers[$n]->[1]</td><td>$comers[$n]->[2]</td><td>";
	
	if ($comers[$n]->[6]) {
	    @allergs = db::select_all_allerg($dbh, $comers[$n]->[6],$udallergy);
	    for (my $n=0; $n < @allergs; $n++) {
		print "$allergs[$n]->[0] ";
	    }
	}
	print "</td><td>";
	
	if ($comers[$n]->[3] == '1') {
	    print "ei n‰ytet‰ mit‰‰n</td><td>\n";
	} elsif ($comers[$n]->[3] == '2') {
	    print "n‰ytet‰‰n vain nimi</td><td>\n";
	} elsif ($comers[$n]->[3] == '3') {
	    print "n‰ytet‰‰n nimi ja email</td><td>\n";
      	} elsif ($comers[$n]->[3] == '4') {
	    print "n‰ytet‰‰n nick</td><td>\n";
      	} elsif ($comers[$n]->[3] == '5') {
	    print "n‰ytet‰‰n nimi ja nick</td><td>\n";
	}
	if ($comers[$n]->[4] == '1') {
	    print "En ajatellut grillata</td><td>";
	} elsif ($comers[$n]->[4] == '2') {
	    print "Saatanpa grillatakin</td><td>";
	} elsif ($comers[$n]->[4] == '3') {
	    print "Grilli kuumaksi</td><td>";
	} elsif ($comers[$n]->[4] == '4') {
	    print "Ei mielipidett‰ grillaukseen</td><td>";
	} elsif ($comers[$n]->[4] == '0') {
	    print "</td><td>";
	}
	if ($comers[$n]->[8] == '1') {
	    print "Parkkitilaa tarvitaan</td><td>";
	} elsif ($comers[$n]->[8] == '0') {
	    print "Ei parkkitilan tarvetta</td><td>";
	} elsif ($comers[$n]->[8] == '2') {
	    print "Ei kommenttia parkkitilasta</td><td>";
	}
	print "$comers[$n]->[5]</td><td>";
	print "$comers[$n]->[9]</td></tr>\n";
    }
}
print "</table><br><input type=\"submit\" name=\"poista\" value=\"Poista valitut\"></form>\n";

my @count = db::select_count($dbh, "1");
print itext::amount(\@count);
my @cars = db::select_car_count($dbh);
print "<br> Autoja tulossa noin $cars[0]->[0].";

print "<h1>Ep‰tulijat</h1>";
print "<form name=\"adminilmo\"method=\"post\"><table border=1>\n";
print "<th></th>";

for (my $n=0; $n < @itext::headers; $n++) { 
    print "<form name=\"adminsort\" method=\"get\">";
    print "<th><input type=\"hidden\" id=\"sort\" name=\"sort\" value=\"$itext::headers[$n]\">$itext::headers[$n] ";
    print "<input type=\"submit\" name=\"up\" value=\"&uarr;\">";
    print "<input type=\"submit\" name=\"down\" value=\"&darr;\"></th>\n";
    print "</form>";
}

for (my $n=0; $n < @comers; $n++) { 
    if (!$comers[$n]->[7]) {
	print "<tr><td><input type=\"checkbox\" id=\"$n\" name=\"$n\"></td><td>$comers[$n]->[0]</td><td>$comers[$n]->[1]</td><td>$comers[$n]->[2]</td><td>";
	
	if ($comers[$n]->[6]) {
	    @allergs = db::select_all_allerg($dbh, $comers[$n]->[6],$udallergy);
	    for (my $n=0; $n < @allergs; $n++) {
		print "$allergs[$n]->[0] ";
	    }
	}
	print "</td><td>";
	
	if ($comers[$n]->[3] == '1') {
	    print "ei n‰ytet‰ mit‰‰n</td><td>\n";
	} elsif ($comers[$n]->[3] == '2') {
	    print "n‰ytet‰‰n vain nimi</td><td>\n";
	} elsif ($comers[$n]->[3] == '3') {
	    print "n‰ytet‰‰n nimi ja email</td><td>\n";
	} elsif ($comers[$n]->[3] == '4') {
	    print "n‰ytet‰‰n nick</td><td>\n";
	} elsif ($comers[$n]->[3] == '5') {
	    print "n‰ytet‰‰n nimi ja nick</td><td>\n";
	}
	if ($comers[$n]->[4] == '1') {
	    print "En ajatellut grillata</td><td>";
	} elsif ($comers[$n]->[4] == '2') {
	    print "Saatanpa grillatakin</td><td>";
	} elsif ($comers[$n]->[4] == '3') {
	    print "Grilli kuumaksi</td><td>";
	} elsif ($comers[$n]->[4] == '4') {
	    print "Ei mielipidett‰ grillaukseen</td><td>";
	} elsif ($comers[$n]->[4] == '0') {
	    print "</td><td>";
	}
	if ($comers[$n]->[8] == '1') {
	    print "Parkkitilaa tarvitaan</td><td>";
	} elsif ($comers[$n]->[8] == '0') {
	    print "Ei parkkitilan tarvetta</td><td>";
	} elsif ($comers[$n]->[8] == '2') {
	    print "Ei kommenttia parkkitilasta</td><td>";
	}
	print "$comers[$n]->[5]</td><td>";
	print "$comers[$n]->[9]</td></tr>\n";
    }
}
print "</table><br><input type=\"submit\" name=\"poista\" value=\"Poista valitut\"></form>\n";
$udallergy = "";
my @count2 = db::select_count($dbh, "0");
print itext::nocomeamount(\@count2);

print "<form name=\"adminexport\"method=\"post\">";
print "<br><input type=\"submit\" name=\"export\" value=\"Exportoi tiedot CSV:ksi\"></form>\n";
print "<a href=\"ilmoallergycount.pl\">Allergiayhteenveto</a><br>";

print itext::endtags();

