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

package itext;

use strict;
use CGI qw/:standard/;

my $title = "Erkin valmistujaispippalot";
my $header = "Ilmoittaudu Erkin valmistujaispippaloihin!";
my @allergies = ("Alkoholiton", "Gluteeniton","Kananmunaton","Laktoositon","Lihaani","Luomu","Luontaisesti gluteeniton","Maidoton","Mauton","Pähkinätön","Rasvaton","Soijalesitiinitön","Soijaton","Suolaton","Viherpiipertäjä","Vähälaktoosinen (Hyla)");
my $name = "Etu- ja sukunimi:";
my $email = "Sähköposti:";
my $allerg = "Rastita:";
my $ilmotext = "Ilmoittaudu!";
my $ohje = "Minusta saa näkyä ilmoittautuneet-sivulla:";
my $ohje1 = "Nimi ja sähköposti";
my $ohje2 = "Vain nimi";
my $ohje3 = "Ei mitään";
my $other = "Joku muu mikä:";
my $tulijat = "Ilmoittautuneet";
my $charerror = "Voivoi, syötit epäkelvon merkin - Yritä uudelleen";
#my $emailerror = "Sähköpostiosoite on pakollinen";
my $tulossa = "Tähän mennessä ilmoittautuneet:";
my $done = "Ilmoittautuminen suoritettu.";
my $takaisin = "Takaisin.";
my $grill = "Grillausta?";
my $grill1 = "En ajatellut grillata";
my $grill2 = "Saatanpa grillatakin";
my $grill3 = "Grilli kuumaksi!";

sub otsikko { return "<html><head><link rel=\"stylesheet\" href=\"ilmo.css\"><title>$title</title></head><body>";}

sub headeri { return "<h1>$header</h1>";}

sub tulossa { return "<h1>$tulossa</h1>";}

sub done { return $done;}

sub formi1 {
    return "<form name=\"ilmottaudu\" method=\"post\"> 
$name<input type=\"text\" name=\"name\" size=30><br>\n \
$email<input type=\"text\" name=\"email\" size=30><br>\n \ 
<br>$grill<br><input type=\"radio\" name=\"grilling\" value=\"nogrill\">$grill1\n \
<input type=\"radio\" name=\"grilling\" value=\"maybegrill\">$grill2\n \
<input type=\"radio\" name=\"grilling\" value=\"yesgrill\">$grill3\n<br><br> \
$allerg";}

sub formi2 {return "<br>$other<input type=\"text\" name=\"addinfo\" size=30><br>\n \
<br>$ohje<br><input type=\"radio\" name=\"privacy\" value=\"allinfo\">$ohje1\n \
<input type=\"radio\" name=\"privacy\" value=\"nameinfo\">$ohje2\n \
<input type=\"radio\" name=\"privacy\" value=\"noinfo\">$ohje3\n \
<br><br><input type=\"submit\" name=\"ilmoa\" value=\"$ilmotext\">\n";}

sub boxes { 
    my $n = shift;
    return "<br><input type=\"checkbox\" id=\"$n\" name=\"$n\"><label for=\"$n\">$allergies[$n]</label>\n";
}

sub namesemail {
    my $n = shift;
    my @values = @{shift()};
    my $email = $values[$n]->[1];
    $email =~ s/\@/ at /g;
    return "<tr><td>$values[$n]->[0], ".$email ."</td>" if ($values[$n]->[1]);
    return "<tr><td>$values[$n]->[0]</td>" if !($values[$n]->[1]);
}

sub names {
    my $n = shift;
    my @values = @{shift()};
    return "<tr><td>$values[$n]->[0]</td>";
}

sub ilmottu {
    my $n = shift;
    my @values = @{shift()};
    return "<td>$values[$n]->[3]</td></tr>\n";
}

sub starttable {return "<table border=0";}

sub endtable {return "</table";}

sub namesnone { return "<tr><td>Anonyymi</td>\n";}

sub endtags {return "</body></html>";}

sub ilmosivu { return "<br><br><br><a href=\"" . url(-relative=>1) . "?tulijat=1\">$tulijat</a>";}

sub takaisin { return "<br><a href=\"".url(-relative=>1)."\">$takaisin</a><br>";}

sub allergy { return @allergies;}

sub charerror { return $charerror;}

#sub emailerror { return $emailerror;}


return 1;
