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
use CGI qw/:standard -debug -utf8/;
use utf8::all;
use lib ".";
use ilmotexts;
use db;

my $dbh=db::connect_db();

sub matrixsend {
    my $message = shift;

    open(F, "| /home/manti/bin/matrix-send.py --config /home/manti/.config/matrix-send/config.ini 2> /home/manti/public_html/ilmo/matrixack.log");
    print F "$message acked";
    close(F);
}

print header("text/html;charset=UTF-8");
print itext::ackotsikko();

if (defined(param('seed'))) {
    db::ack_email($dbh,param('seed'));
    print itext::ack();

    my @ackperson = db::select_who_ack($dbh,param('seed'));
    matrixsend($ackperson[0]->[0]);
}

print itext::endtags();
