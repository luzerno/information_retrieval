#!/usr/bin/perl
sub test {
    return (1, 2, 3);
}
my ($a, $b, $c) = &test;
print $a, $b, $c;
print &test;
@a = (1, 2, 3, 4, 5);
@b = (2, 3, 4, 5, 6);
print @a + @b;



if ("default" =~ /1a|1c/) {
    print "yes";
} else {
    print "no"
}
