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

my $title = "Tuparit!";
my $header = "Ilmoittaudu Marjan ja Erkin tupareihin!";
my $name = "Etu- ja sukunimi:";
my $email = "Sähköposti:";
my $allerg = "Rastita:";
our $ilmotext = "Ilmoittaudu!";
my $ohje = "Minusta saa näkyä ilmoittautuneet-sivulla:";
our $ohje1 = "Nimi ja sähköposti";
our $ohje2 = "Vain nimi";
our $ohje3 = "Ei mitään";
my $other = "Joku muu mikä:";
my $tulijat = "Ilmoittautuneet";
my $muokkaa = "Muokkaa tietoja";
my $charerror = "Voivoi, syötit epäkelvon merkin - Yritä uudelleen";
my $tulossa = "Tähän mennessä ilmoittautuneet:";
my $done = "Ilmoittautuminen suoritettu.";
my $takaisin = "Takaisin.";
my $grill = "Grillausta?";
our $grill1 = "En ajatellut grillata";
our $grill2 = "Saatanpa grillatakin";
our $grill3 = "Grilli kuumaksi!";
my $nick = "Irc nick";
my $pw = "Anna salasana jonka avulla voit myöhemmin muuttaa tietojasi. Koneellesi tallennetaan myös cookie.";
my $askpw = "Salasana:";
my $mheader = "Tietojen muokkaus";
my $showinfo = "Näytä tiedot";
our $change = "Muuta tietoja";
our $remove = "Poista ilmoittautuminen";
my $anon = "Anonyymi";

sub coalesce { 
    my $value = shift; 
    while (!defined $value) { 
	$value = shift; 
    } 
    return $value; 
}

sub otsikko { return "<html><head><link rel=\"stylesheet\" href=\"ilmo.css\"><title>$title</title></head><body>";}

sub headeri { return "<h1>$header</h1>";}

sub tulossa { return "<h1>$tulossa</h1>";}

sub mheader { return "<h1>$mheader</h1>";}

sub done { return $done;}

sub kysypw {
    return "<form name=\"askpw\" method=\"post\"> \
$name<input type=\"text\" name=\"apwname\" size=30><br>\n
$askpw<input type=\"password\" name=\"apw\" size=30><br>\n
<br><input type=\"submit\" name=\"subpw\" value=\"$showinfo\">\n";}

sub formi1alku {
    my $formname = shift;
    my @info = @{shift() || []};
    @info = coalesce(@info, ["", ""]);
    return "<form name=\"$formname\" method=\"post\"> \
$name<input type=\"text\" name=\"name\" size=30 value=\"$info[0]->[0]\"><br>\n \
$email<input type=\"text\" name=\"email\" size=30 value=\"$info[0]->[1]\"><br>\n";}

sub formi1nick {
    my @info = @{shift() || []};
    @info = coalesce(@info, ["", "", ""]);
    return "$nick<input type=\"text\" name=\"nick\" size=30 value=\"$info[0]->[2]\"><br>\n";}

sub formi1grill1 {
    return "<br>$grill<br>";}

sub formi1grill2c {
    my $val= shift;
    my $grill = shift;
    return "<input type=\"radio\" name=\"grilling\" value=\"$val\" checked>$grill\n";}

sub formi1grill2 {
    my $val= shift;
    my $grill = shift;
    return "<input type=\"radio\" name=\"grilling\" value=\"$val\">$grill\n";}

sub formi1grill3 {
    return "<br><br>";}

sub addfield {
    my $val = coalesce(shift, "");
    return "<br>$other<input type=\"text\" name=\"addinfo\" size=30 value=\"$val\"><br>\n";}

sub formpria {return "<br>$ohje<br>";} 

sub formpri {
    my $val = shift;
    my $info = shift;    
    return "<input type=\"radio\" name=\"privacy\" value=\"$val\">$info\n";}

sub formpric {
    my $val = shift;
    my $info = shift;    
    return "<input type=\"radio\" name=\"privacy\" value=\"$val\" checked>$info\n";}

sub formpw {return "<br><br>$pw<br><input type=\"password\" name=\"pw\" size=30><br><br><br>\n";}

sub formend {
    my $val = shift;
    my $buttontext = shift;
    return "<input type=\"submit\" name=\"$val\" value=\"$buttontext\">\n<br>";} 

sub boxes { 
    my $n = shift;
    my @allergies = @{shift()};
    return "<br><input type=\"checkbox\" id=\"$n\" name=\"$n\"><label for=\"$n\">$allergies[$n]</label>\n";
}

sub boxescheck { 
    my $n = shift;
    my @allergies = @{shift()};
    return "<br><input type=\"checkbox\" id=\"$n\" name=\"$n\" checked><label for=\"$n\">$allergies[$n]</label>\n";
}

sub allerg {
    return "$allerg";
}

sub namesemail {
    my $n = shift;
    my @values = @{shift()};
    my $email = $values[$n]->[1];
    $email = coalesce($email, "");
    $email =~ s/\@/ at /g;
    return "<tr><td>$values[$n]->[0], ".$email ."</td>" if ($values[$n]->[1]);
    return "<tr><td>$values[$n]->[0]</td>" if !($values[$n]->[1]);
}

sub names {
    my $n = shift;
    my @values = @{shift()};
    return "<tr><td>$values[$n]->[0]</td>";
}

sub amount {
    my @n = @{shift()};
    return "<br><br><br>$n[0]->[0] tulijaa.";
}

sub ilmottu {
    my $n = shift;
    my @values = @{shift()};
    return "<td>$values[$n]->[3]</td></tr>\n";
}

sub starttable {return "<table border=0";}

sub endtable {return "</table";}

sub namesnone { return "<tr><td>$anon</td>\n";}

sub endtags {return "</body></html>";}

sub ilmosivu { return "<br><br><br><a href=\"" . url(-relative=>1) . "?tulijat=1\">$tulijat</a>";}

sub muokkaa { return "<br><a href=\"".url(-relative=>1)."?mpw=1\">$muokkaa</a>";}

sub takaisin { return "<br><a href=\"".url(-relative=>1)."\">$takaisin</a><br>";}

sub charerror { return $charerror;}

return 1;
