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
    my $values = shift;
    my $sth;

    $sth = $dbh->prepare("INSERT INTO participants (name, email, allergy) VALUES (?,?,?)")
	or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($name, $email, $values);
    $sth->finish;
}

sub select_names {

    my $dbh = shift;

    return 
	select_generic($dbh,
		       sub{return [@_]},
		       "SELECT name FROM participants");
}

# sub select_from_item_shop_person {

#     my $dbh = shift;
#     my $list = shift;
#     my $person = shift;
#     return 
# 	select_generic($dbh,
# 		       sub{return [@_]},
# 		       "SELECT item, name, EXTRACT(EPOCH FROM added_orig), bolded FROM item LEFT JOIN class ON name = cname WHERE list = ? and ingroup is null and personal = ? and (postponed_until < now() OR postponed_until is null) ORDER BY class, item",
# 		       $list, $person);
# }


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

# sub select_bolded {
#     my $dbh = shift;
#     my $val = shift;
    
#     return 
# 	select_generic_scalar($dbh,
# 			      sub{return $_},
# 			      "SELECT bolded FROM item where item = ?",
# 			      $val);
# }

# sub select_generic_scalar {

#     my $dbh = shift;
#     my $mapping = shift;
#     my $stm = shift;
#     my @args = @_;

#     my $sth;
#     my $item;

#     $sth = $dbh->prepare($stm)
# 	or die "Couldn't prepare statement: " . $dbh->errstr;

#     $sth->execute(@args);

#     $item = ($sth->fetchrow())[0];
#     $sth->finish;

#     return $item;
# }


# sub clear_all {
#     my $dbh = shift;
#     my $list = shift;
    
#     my $sth;
    
#     $sth = $dbh->prepare("DELETE FROM item WHERE list = ?")
# 	or die "Couldn't prepare statement: " . $dbh->errstr;
#     $sth->execute($list);    
    
#     $sth->finish;
# }

# sub delete_item {
#     my $dbh = shift;
#     my $item = shift;
    
#     my $sth;
    
#     $sth = $dbh->prepare("DELETE FROM item WHERE item = ?")
# 	or die "Couldn't prepare statement: " . $dbh->errstr;
#     $sth->execute($item);        
#     $sth->finish;
# }


return 1;
