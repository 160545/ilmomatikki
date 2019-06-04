#!/usr/bin/perl -w

# Copyright manti <manti@modeemi.fi> 2011-2018

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
use lib "."; 
use ilmotexts;
use db;

my $dbh=db::connect_db();

my @allergyheaders;
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


# virhekäsittely tehdään eval-lohkon päätteeksi (diellä ilmoitetaan virheet)
#eval {
#};

print header("text/html;charset=UTF-8");
#print itext::otsikko();

print "<h1>Allergiayhteenveto</h1>";
print "<table>";
for (my $n=0; $n < @allergyheaders; $n++) {
    my @nbr = db::select_all_count($dbh, $allergyheaders[$n]);
    print "<tr><td>$allergyheaders[$n]:</td><td> $nbr[0]->[0] kpl</td></tr>";
}
print "</table>";
print itext::endtags();

