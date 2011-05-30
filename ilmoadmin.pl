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

# virhek‰sittely tehd‰‰n eval-lohkon p‰‰tteeksi (diell‰ ilmoitetaan virheet)
eval {
    if (param('poista')) {
	my @values;
	my @value = grep {/^[0-9]+$/} param();
	my @items = db::select_all_part($dbh);

	foreach my $item (@value) {
	    push(@values, $items[$item]);
	}

	for (my $n; $n < @values; $n++) {
	    db::delete_record($dbh, $values[$n]->[0], $values[$n]->[5]);
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
print "<h1>Tulijat:</h1>";
print "<form name=\"adminilmo\"method=\"post\"><table border=1>";
my @comers = db::select_all_part($dbh);
my @allergs;

for (my $n=0; $n < @comers; $n++) { 
#    my @aid = db::select_id($dbh, $comers[$n]->[0], $comers[$n]->[5]);

    print "<tr><td><input type=\"checkbox\" id=\"$n\" name=\"$n\"></td><td>$comers[$n]->[0]</td><td>$comers[$n]->[1]</td><td>$comers[$n]->[2]</td><td>";

    if ($comers[$n]->[6]) {
	@allergs = db::select_all_allerg($dbh, $comers[$n]->[6]);
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
    }
    if ($comers[$n]->[4] == '1') {
	print "En ajatellut grillata</td><td>\n";
    } elsif ($comers[$n]->[4] == '2') {
	print "Saatanpa grillatakin</td><td>\n";
    } elsif ($comers[$n]->[4] == '3') {
	print "Grilli kuumaksi</td><td>\n";
    } elsif ($comers[$n]->[4] == '4') {
	print "Ei mielipidett‰ grillaukseen</td><td>\n";
    } elsif ($comers[$n]->[4] == '0') {
	print "</td><td>\n";
    }
    print "$comers[$n]->[5]</td></tr>\n";
}
print "</table><br><input type=\"submit\" name=\"poista\" value=\"Poista valitut\">\n";

my @count = db::select_count($dbh);

print itext::amount(\@count);
print itext::endtags();

