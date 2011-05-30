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

sub debug {
    my $msg = shift;
    open(F, ">>", "/home/manti/public_html/ilmodev/ilmodebug.log");
    print F "$$ $msg\n";
    close(F);
}

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
    my $pw = shift;
    my $grill = shift;
    my $nick = shift;
    my $time = shift;
    my $coo = shift;
    my $sth;
    my $sth2;
    
    if ($nick eq 'undef') {
	$nick = '';
    }
    
    $dbh->begin_work;
    $sth = $dbh->prepare("INSERT INTO participants (name, email, privacy, passwd, grill, cookie, submitted, nick) VALUES (?,?,?,?,?,?,?,?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($name, $email, $privacy, $pw, $grill, $coo, $time, $nick);
    $sth->finish;
    
    if (@values) {
	foreach my $item (@values) {
	    $sth2 = $dbh->prepare("INSERT INTO allergies (allergy, id) VALUES (?,(SELECT id FROM participants WHERE name = ? and submitted = ?))")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	    $sth2->execute($item, $name, $time);
	    $sth2->finish;
	}
    }
    $dbh->commit;
}

sub update_comers {
    my $dbh = shift;
    my $name = shift;
    my $email = shift;
    my @values = @{shift()};
    my $privacy = shift;
    my $grill = shift;
    my $nick = shift;
    my $time = shift;
    my $coo = shift;
    my $pw = shift;
    my $sth;
    my $sth2;
    my $sth3;
    my $column;
    my $pworcoo;
    
    if ($nick eq 'undef') {
	$nick = '';
    }
    
    if (defined($coo) && !defined($pw)) {
	$column="cookie";
	$pworcoo=$coo;
    } elsif (!defined($coo) && defined($pw)) {
	$column="passwd";
	$pworcoo=$pw;
    }
    
    $dbh->begin_work;
    $sth = $dbh->prepare("UPDATE participants SET name=?, email=?, privacy=?, grill=?, submitted=?, nick=? WHERE $column=?")
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($name, $email, $privacy, $grill, $time, $nick, $pworcoo);
    $sth->finish;
    
    $sth2 = $dbh->prepare("DELETE from allergies WHERE id=(SELECT id FROM participants WHERE $column=?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute($pworcoo);
    $sth2->finish;    
    
    if (@values) {
	foreach my $item (@values) {
	    $sth3 = $dbh->prepare("INSERT INTO allergies (allergy, id) VALUES (?, (SELECT id FROM participants WHERE $column=?))")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	    $sth3->execute($item, $pworcoo);
	    $sth3->finish;
	}
    }
    $dbh->commit;
}

sub delete_record {
    my $dbh = shift;
    my $name = shift;
    my $time = shift;
    my $sth;
    my $sth2;

    $dbh->begin_work;
    $sth2 = $dbh->prepare("DELETE from allergies WHERE id = (SELECT id FROM participants WHERE name = ? and submitted = ?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute($name, $time);
    $sth2->finish;
    
    $sth = $dbh->prepare("DELETE from participants WHERE name = ? and submitted = ?")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($name, $time);
    $sth->finish;
    
    $dbh->commit;
}


sub delete_user {
    my $dbh = shift;
    my $pw = shift;
    my $coo = shift;
    my $column = "";
    my $pworcoo;

    my $sth;
    my $sth2;
    
    if (defined($coo) && !defined($pw)) {
	$column="cookie";
	$pworcoo=$coo;
    } elsif (!defined($coo) && defined($pw)) {
	$column="passwd";
	$pworcoo=$pw;
    }

    $dbh->begin_work;
    $sth2 = $dbh->prepare("DELETE from allergies WHERE id = (SELECT id FROM participants WHERE $column = ?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute($pworcoo);
    $sth2->finish;
    
    $sth = $dbh->prepare("DELETE from participants WHERE $column = ?")
 	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($pworcoo);
    $sth->finish;
    
    $dbh->commit;
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

sub select_cookie {
    my $dbh = shift;
    my $name = shift;
    my $pw = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT cookie FROM participants WHERE name = ? and passwd = ?",
		       $name,$pw);
}

sub select_all_part {
    my $dbh = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, submitted, id FROM participants ORDER BY submitted");
}

sub select_for_pw {
    my $dbh = shift;
    my $pw = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, passwd, id, submitted FROM participants WHERE passwd = ? AND cookie = ?",
		       $pw, $cookie);
}

sub select_for_cookie {
    my $dbh = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, passwd, id, submitted FROM participants WHERE cookie = ?",
		       $cookie);
}

sub select_all_allerg {
    my $dbh = shift;
    my $id = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT allergy FROM allergies WHERE id = ?",
		       $id);
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
