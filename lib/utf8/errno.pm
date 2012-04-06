package utf8::errno;
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

_reset_global($_) for $!;

sub import {
	$^H |= 0x020000;
	$^H{errno_utf8} = 1;
	return;
}

sub unimport {
	$^H |= 0x020000;
	$^H{errno_utf8} = 0;
	return;
}

1;

# ABSTRACT: UTF-8 safe $!

__END__

=head1 SYNOPSIS

 use utf8::errno;

 die $!;

=head1 DESCRIPTION

This module overrides the magic on C<$!> to make it use utf8. This should only be used when you're sure you're using a utf8(-compatible) locale.

=begin Pod::Coverage

unimport

=end Pod::Coverage
