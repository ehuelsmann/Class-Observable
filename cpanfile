requires 'strict';
requires 'warnings';
requires 'Scalar::Util';

requires 'Class::ISA', '0.32';

on test => sub {
	requires 'Test::More', '0.88';
	requires 'base';
	requires 'lib';
};

# vim: ft=perl
