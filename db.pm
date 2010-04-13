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

package db;

use strict;
use CGI qw/:standard/;
use DBI;

#global database handler, slow to create & disconnect all the time, done only once

sub connect_db {

    # variables for DB
    my $host = "modeemi";
    my $db = "ilmo";
    my $user = "manti";
    
    return DBI->connect('DBI:Pg:host='.$host.';dbname='.$db,$user) or die "Couldn't connect to database: " . DBI->errstr;
}

sub insert_comers {
    my $dbh = shift;
    my $name = shift;
    my $email = shift;
    my @values = @{shift()};
    my $privacy = shift;
    my $grill = shift;
    my $nick = shift;
    my $time = shift;
    my $sth;
    my $sth2;

    if ($nick eq 'undef') {
	$nick = '';
    }

    if (@values) {
	$dbh->begin_work;
	$sth = $dbh->prepare("INSERT INTO participants (name, email, privacy, grill, submitted, nick, allergyid) VALUES (?,?,?,?,?,?,(SELECT COALESCE(MAX(allergyid),0)+1 FROM participants))")
	or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($name, $email, $privacy, $grill, $time, $nick);
	$sth->finish;
	
	foreach my $item (@values) {
	    $sth2 = $dbh->prepare("INSERT INTO allergies (allergy, id) VALUES (?,(SELECT allergyid FROM participants WHERE name = ? and submitted = ?))")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	    $sth2->execute($item, $name, $time);
	    $sth2->finish;
	}
	$dbh->commit;
    } else {
	$sth = $dbh->prepare("INSERT INTO participants (name, email, privacy, grill, submitted, nick) VALUES (?,?,?,?,?,?)")
	    or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute($name, $email, $privacy, $grill, $time, $nick);
	$sth->finish;
    }
}

sub delete_record {
    my $dbh = shift;
    my $name = shift;
    my $time = shift;
    my $sth;

    $sth = $dbh->prepare("DELETE from participants WHERE name = ? and submitted = ?")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($name, $time);
    $sth->finish;
}

sub select_names {

    my $dbh = shift;

    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, privacy, submitted FROM participants ORDER BY submitted");
}

sub select_count {

    my $dbh = shift;

    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(name) FROM participants");
}

sub select_all {
    my $dbh = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, allergy, privacy, grill, submitted FROM participants ORDER BY submitted");
}

sub select_generic {

    my $dbh = shift;
    my $mapping = shift;
    my $stm = shift;
    my @args = @_;

    my $sth;
    my @values;
    my @items;

    $sth = $dbh->prepare($stm)
	or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth->execute(@args);

    while(@items=$sth->fetchrow()) {
        push(@values, &$mapping(@items));
    }

    $sth->finish;

    return @values;
}

return 1;
