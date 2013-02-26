# Locale::Po4a::Colobothelp -- Convert Colobot help files
#
# This program is free software; you may redistribute it and/or modify it
# under the terms of GPLv3.
#

use Locale::Po4a::TransTractor qw(process new);
use Locale::Po4a::Common;
use Locale::Po4a::Text;

package Locale::Po4a::Colobothelp;

use 5.006;
use strict;
use warnings;

require Exporter;

use vars qw(@ISA @EXPORT $AUTOLOAD);
@ISA = qw(Locale::Po4a::TransTractor);
@EXPORT = qw();

my @comments = ();
my $tabs = "";
my $breaks;

sub initialize {}

sub parse {
    my $self = shift;
    my ($line,$ref);
    my $paragraph="";
    my $wrapped_mode = 1;
    my $expect_header = 1;
    my $end_of_paragraph = 0;
    ($line,$ref)=$self->shiftline();
    while (defined($line)) {
        chomp($line);
        $self->{ref}="$ref";
        ($paragraph,$wrapped_mode,$expect_header,$end_of_paragraph) = parse_colobothelp($self,$line,$ref,$paragraph,$wrapped_mode,$expect_header,$end_of_paragraph);
        # paragraphs starting by a bullet, or numbered
        # or paragraphs with a line containing many consecutive spaces
        # (more than 3)
        # are considered as verbatim paragraphs
        $wrapped_mode = 0 if (   $paragraph =~ m/^(\*|[0-9]+[.)] )/s
                          or $paragraph =~ m/[ \t][ \t][ \t]/s);
        $wrapped_mode = 0 if (    $tabs eq "verbatim"
                              and $paragraph =~ m/\t/s);
        if ($end_of_paragraph) {
            Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
            $paragraph="";
            $wrapped_mode = 1;
            $end_of_paragraph = 0;
        }
        ($line,$ref)=$self->shiftline();
    }
    if (length $paragraph) {
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
    }
}

sub parse_colobothelp {
    my ($self,$line,$ref,$paragraph,$wrapped_mode,$expect_header,$end_of_paragraph) = @_;
    if (   ($line =~ /^\s*$/)
             or (    defined $breaks
                 and $line =~ m/^$breaks$/)) {
        # Break paragraphs on lines containing only spaces
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph="";
        $wrapped_mode = 1 unless defined($self->{verbatim});
        $self->pushline($line."\n");
        undef $self->{controlkey};
    } elsif ($line =~ /^\\[bt];/) {
        # Break paragraphs on \b; or \t; headers
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph="";
        $wrapped_mode = 1;

	$line =~ s/^\\([bt]);//;
        $self->pushline("\\$1;".$self->translate($line,$ref,"\\$1; header")."\n");
    } elsif (   $line =~ /^=+$/
             or $line =~ /^_+$/
             or $line =~ /^-+$/) {
        $wrapped_mode = 0;
        $paragraph .= $line."\n";
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph="";
        $wrapped_mode = 1;
    } elsif ($tabs eq "split" and $line =~ m/\t/ and $paragraph !~ m/\t/s) {
        $wrapped_mode = 0;
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph = "$line\n";
        $wrapped_mode = 0;
    } elsif ($tabs eq "split" and $line !~ m/\t/ and $paragraph =~ m/\t/s) {
        Locale::Po4a::Text::do_paragraph($self,$paragraph,$wrapped_mode);
        $paragraph = "$line\n";
        $wrapped_mode = 1;
    } else {
        if ($line =~ /^\s/) {
            # A line starting by a space indicates a non-wrap
            # paragraph
            $wrapped_mode = 0;
        }
        undef $self->{bullet};
        undef $self->{indent};
# TODO: comments
        $paragraph .= $line."\n";
    }
    return ($paragraph,$wrapped_mode,$expect_header,$end_of_paragraph);
}

1;
__END__
