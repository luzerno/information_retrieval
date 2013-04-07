#!/usr/bin/perl

if (my ($num) = ".I14 12" =~ /^\.I\s\d*\s(\d*)/) {
    print "yes";
} else {
    print "no";
}
print $num;

sub test {
    my @a = ();
    push @a, 1;
    push @a, 2;
    return @a;
}

my @x = &test;
print @x;


%a = ("hel", 1, "ho", 2, "jk", 3);
while (my ($key, $value) = each(%a)) {
    $value += 1;
}

while (my ($key, $value) = each(%a)) {
    print $key, " ", $value, "\n";
}

%b = ();

$b{"hello"} += 1;
print %b;
