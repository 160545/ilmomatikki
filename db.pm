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

package db;

use strict;
use CGI qw/:standard/;
use DBI;

my $configfile = "config";

my $debuglog;
my $host;
my $user;
my $db;

my $printdebug=0;

#read DB connection details from config file
if (open(F, "<", $configfile)) {
    my @temparr;
    my $line;
    while ($line = <F>) {
	chomp $line;
	if ($line =~ /^dbhost/) {
	    @temparr = split(/\= */,$line);
	    $host = $temparr[1];
	} elsif ($line =~ /^dbuser/) {
	    @temparr = split(/\= */,$line);
	    $user = $temparr[1];
	} elsif ($line =~ /^database/) {
	    @temparr = split(/\= */,$line);
	    $db = $temparr[1];
	} elsif ($line =~ /^debuglog/) {
	    @temparr = split(/\= */,$line);
	    $debuglog = $temparr[1];
	}
    }
}
close (F);
	

sub debug {
    my $msg = shift;
    if ($printdebug) {
	open(F, ">>", $debuglog);
	print F "$$ $msg\n";
	close(F);
    }
}

#global database handler, slow to create & disconnect all the time, done only once
sub connect_db {
    return DBI->connect('DBI:Pg:host='.$host.';dbname='.$db,$user) or die "Couldn't connect to database: " . DBI->errstr;
}


sub ack_email {
    my $dbh = shift;
    my $id = shift;
    my $sth;
    
    $dbh->begin_work;
    $sth = $dbh->prepare("UPDATE ack SET acktime=NOW() WHERE seed = ? and acktime is null")
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($id);
    $sth->finish;
    
    $dbh->commit;
}


sub admin_ack_email {
    my $dbh = shift;
    my $id = shift;
    my $sth;
    
    $dbh->begin_work;
    $sth = $dbh->prepare("UPDATE ack SET adminacktime=NOW() WHERE seed = ? and acktime is null")
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($id);
    $sth->finish;
    
    $dbh->commit;
}

sub select_no_ack {
    my $dbh = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT email, seed FROM ack WHERE acktime is null and adminacktime is null ");
}

sub insert_comers {
    my $dbh = shift;
    my $limitgroup = shift;
    my $name = shift;
    my $email = shift;
    my @values = @{shift()};
    my $privacy = shift;
    my $pw = shift;
    my $grill = shift;
    my $nick = shift;
    my $car = shift;
    my $time = shift;
    my $coo = shift;
    my $none= shift;
    my $sth;
    my $sth2;
    
    if ($nick eq 'undef') {
	$nick = '';
    }
    
    $dbh->begin_work;
    $sth = $dbh->prepare("INSERT INTO participants (limitgroup, name, email, privacy, passwd, grill, cookie, submitted, nick, notcoming, car) VALUES (?,?,?,?,?,?,?,?,?,?,?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($limitgroup, $name, $email, $privacy, $pw, $grill, $coo, $time, $nick, $none, $car);
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
    my $limitgroup = shift;
    my $name = shift;
    my $email = shift;
    my @values = @{shift()};
    my $privacy = shift;
    my $grill = shift;
    my $nick = shift;
    my $car = shift;
    my $none = shift;
#    my $time = shift;
    my $coo = shift;
    my $pw = shift;
    my $id = shift;
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
    $sth = $dbh->prepare("UPDATE participants SET submitted=CASE WHEN notcoming<>? THEN NOW() ELSE submitted END, limitgroup=?, name=?, email=?, privacy=?, grill=?, nick=?, car=?, notcoming=? WHERE $column=? AND id = ?")
        or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($none, $limitgroup, $name, $email, $privacy, $grill, $nick, $car, $none, $pworcoo, $id);
    $sth->finish;
    
    $sth2 = $dbh->prepare("DELETE from allergies WHERE id=(SELECT id FROM participants WHERE $column=? and id = ?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute($pworcoo, $id);
    $sth2->finish;    
    
    if (@values) {
	foreach my $item (@values) {
	    $sth3 = $dbh->prepare("INSERT INTO allergies (allergy, id) VALUES (?, (SELECT id FROM participants WHERE $column=? AND id = ?))")
		or die "Couldn't prepare statement: " . $dbh->errstr;
	    $sth3->execute($item, $pworcoo, $id);
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
    my $id = shift;
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
    $sth2 = $dbh->prepare("DELETE from allergies WHERE id = (SELECT id FROM participants WHERE $column = ? AND id = ?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;

    debug("sql1:".$sth2);
    debug($sth2->{Statement});
    debug($dbh->{Statement});

    $sth2->execute($pworcoo, $id);
    $sth2->finish;

    debug($sth2->{Statement});
    debug($dbh->{Statement});    
	
    $sth = $dbh->prepare("DELETE from participants WHERE $column = ? AND id = ?")
 	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($pworcoo, $id);
    my $scalar = '';
    open( my $fh, "+>:scalar", \$scalar );
    $dbh->trace( 2, $fh );

    debug($scalar);
    debug($sth->{Statement});
    debug($dbh->{Statement});
    $sth->finish;
    
    $dbh->commit;
}

sub select_names {
    my $dbh = shift;
    my $nocome = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, privacy, submitted, nick FROM participants WHERE notcoming=? ORDER BY submitted",
		       $nocome);
}

sub select_all_count {
    my $dbh = shift;
    my $item = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(allergy) FROM allergies WHERE allergy=?",
		       $item);
}

sub select_count {
    my $dbh = shift;
    my $come = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(name) FROM participants WHERE notcoming=?",
		       $come);
}

sub select_car_count {
    my $dbh = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(car) FROM participants WHERE car=1 and notcoming=1",
		       );
}

sub select_igroup_count {
    my $dbh = shift;
    my $come = shift;
    my $igroup = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(name) FROM participants WHERE notcoming=? AND limitgroup=?",
		       $come, $igroup);
}

sub count_grill_percent {
    my $dbh = shift;
    my $grill = shift;
    return
        select_generic($dbh,
                       sub{return [@_]},
		       "SELECT ROUND(100*(SELECT COUNT(*) FROM participants WHERE grill=? and notcoming='1')/(SELECT COUNT(*) FROM participants WHERE notcoming='1'))",
		       $grill);
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

sub select_cookie_exists {
    my $dbh = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT cookie FROM participants WHERE cookie = ?",
		       $cookie);
}

sub select_all_part {
    my $dbh = shift;
    my $order = shift;
    my $up = shift;
    my $sql = "";

    if (!defined($order)) {
	$sql = "ORDER BY submitted";
    } else {
	if ($up == "0") {
	    $sql = "ORDER BY $order ASC";
	} elsif ($up == "1") {
	    $sql = "ORDER BY $order DESC";
	}
    }
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, submitted, id, notcoming, car, limitgroup FROM participants $sql");   
}

sub select_for_pw {
    my $dbh = shift;
    my $pw = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, passwd, id, submitted, notcoming, car FROM participants WHERE passwd = ? AND cookie = ?",
		       $pw, $cookie);
}

sub select_for_cookie {
    my $dbh = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, passwd, id, submitted, notcoming, car FROM participants WHERE cookie = ?",
		       $cookie);
    
}

sub select_for_id {
    my $dbh = shift;
    my $id = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name, email, nick, privacy, grill, passwd, id, submitted, notcoming, car FROM participants WHERE id = ?",
		       $id);
}

sub select_cookie_count {
    my $dbh = shift;
    my $cookie = shift;
    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT COUNT(cookie) FROM participants WHERE cookie = ?",
		       $cookie);
}

sub select_all_allerg {
    my $dbh = shift;
    my $id = shift;
    my $order = shift;
    my $sql = "";

    if (!defined($order)) {
        $sql = "ORDER by allergy ASC";
    } else {
	if ($order eq "all_down_asc") {
	    $sql = "ORDER by allergy ASC";
	} elsif ($order eq "all_up_desc") {
	    $sql = "ORDER by allergy DESC";
	}
    }

    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT allergy FROM allergies WHERE id = ? $sql",
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
