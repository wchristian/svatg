#!/usr/bin/perl

# Rebuilds the beautiful SVatG website

use warnings;
use strict;

use Data::Dumper;

# Link classes and columns
my @link_classes = ("twolink", "threelink", "fourlink", "fivelink");
my @types = ("Demo", "Intro", "Game");

# Temporary file file handle
open my $temp_file, ">", "demos_center.txt";

# Single prod HTML printer
sub output_single_prod {
    my @prod = @{shift()};
    my $title = $prod[0];
    my $image = $prod[1];
    my $primary_link = $prod[2];
    my @links = @{$prod[3]};
    my $link_class = $link_classes[(scalar @links) - 2];
    print $temp_file '        <td class="full">' . "\n";
    print $temp_file '            <div>' . "\n";
    print $temp_file '            <div class="lower">' . "\n";
    print $temp_file '            <div class="linkcont">' . "\n";
    foreach my $link_counter (0..((scalar @links) - 1)) {
        my $class_suffix = "";
        if($link_class eq "fivelink") {
            $class_suffix = $link_counter < 2 ? "_a" : "_b";
        }
        
        my @link = @{$links[$link_counter]};
        print $temp_file '                <a class="' . $link_class . $class_suffix . '" href="' . $link[0] . '"><span>' . $link[1] . '</span></a>' . "\n";
    }
    print $temp_file '            </div>' . "\n";
    print $temp_file '            </div>' . "\n";
    
    print $temp_file '            <a class="upper" href="' . $primary_link . '">' . "\n";
    print $temp_file '            <div class="imagecont"><img src="images/' . $image . '" alt="' . $title . '"/>';
    print $temp_file '<h3>' . $title . '</h3></div>' . "\n";
    print $temp_file '            </a>' . "\n";
    
    print $temp_file '            </div>' . "\n";
    print $temp_file '        </td>' . "\n";
}

# Create storage for prods
my %prods = ();
foreach(@types) {
    $prods{lc($_)} = [];
}

# Read prods
my @links = ();
my $type = "";
my $title = "";
my $image = "";
my $primary_link = "";
while(<>) {
    # Skip comments and whitespace
    if($_ =~ /^#/ || $_ =~ /^\s$/) {
        next;
    }
    
    # New demo
    if($_ =~ /^~([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\n/) {
        # Store old
        if(scalar @links > 0) {
            my @prod = ($title, $image, $primary_link, [@links]);
            push @{$prods{lc($type)}}, \@prod;
        }
        
        # Prepare new
        $type = $1;
        $title = $2;
        $image = $3;
        $primary_link = $4;
        @links = ();
        print "Adding $type: $title\n";
        next;
    }
    
    # Otherwise it's a link
    my ($url, $text) = ($_ =~ /([^\s]*)\s(.*)/);
    print "\t$text -> $url\n";
    push @links, [$url, $text];
}

# Store last
my @prod = ($title, $image, $primary_link, [@links]);
push @{$prods{lc($type)}}, \@prod;

# Figure out which category has the most entries
my @prod_counts = map{scalar @{$prods{lc($_)}}} @types;
my $max_prod_counter = (sort { $b <=> $a } @prod_counts)[0];

# Print new web sight center
my $type_counter = -1;
my $prod_counter = 0;
my $done = 0;
print $temp_file "        <tr>\n";
while(!$done) {
    if($type_counter == 2) {
        $prod_counter++;
        print $temp_file "        </tr>\n";
        if($prod_counter == $max_prod_counter) {
            last;
        }
        print $temp_file "        <tr>\n";
    }
    $type_counter = ($type_counter + 1) % 3;
    my $prod_ref = $prods{lc($types[$type_counter])}->[$prod_counter];
    if(!defined $prod_ref) {
        print $temp_file "        <td></td>\n";
        next;
    }
    output_single_prod($prod_ref);
}

# Concat head, center and foot to make new web sight
close $temp_file;
system("cat demos_header.txt demos_center.txt demos_footer.txt > index.html");

# Done
print "Website updated! Don't forget to push and pull!\n"
