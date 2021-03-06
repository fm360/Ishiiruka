#!/usr/bin/perl -w
use strict;

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

my $filename = shift;

open(CL, "<$filename") or die "Can't open cl.h";

my ($funcRet, $funcName, $args);

print "// Automatically generated by generateClRun.pl\n";
print "#include \"dynamiclib.h\"\n";
print "#include \"$filename\"\n\n\n";

while(<CL>) {
	chomp;
	next unless $_ =~ /CL_API_ENTRY\s*(.*)\s*CL_API_CALL/;
	$funcRet = $1;
	my $fa = "";
        my $noArgs = 0;
	while(<CL>) {
		$fa .= $_;
		last if $_ =~ /;$/;
	}

	chomp $fa;
	$fa =~ s/\s*\).*;\s*$/\)/g; # remove api
	$fa =~ /([^(]*)\((.*)\)/s;
 	$funcName = $1;
	$args = $2;
	
	# split params by , (ignoring function pointers)
	(my @args) = $args =~  m/([^(,]*(?:\([^)]+\)[^(),]*)*[^),]*),?/g;
        
	my (@argsTypes, @argsNames);

	my $funcArgSig = "";
	my $tmp;
	foreach my $arg (@args) {
		
		next if ($arg eq "");
		my ($type, $name) = $arg =~ m|\s*(.*)\s*/\*\s*(.*)\s*\*/|s;
               
                # Strip []
                if(defined $name) {
                	$name =~ s/\[.*\]//g;
                }

		if ($arg =~ /\(.*\)/) {
			$tmp = $type;
			$type =~ s/\(\*.*?\)/\(\*\)/g 
		}
		
		push @argsTypes, trim($type);
		push @argsNames, trim($name);

		if ($arg =~ /\(.*\)/) {
			$funcArgSig .= "$tmp,";
		} elsif(defined $type) {
			$funcArgSig .= trim($type)." ".trim($name).",";
		} else { # Functions with no arguments (i.e. "void" only)
                	$funcArgSig = "void,";
                        $noArgs = 1;
                        last;
                }
	}

	chop($funcArgSig); #last ,

        my ($funcArgsNames, $funcArgsTypes);

        if($noArgs eq 0) {
          $funcArgsNames = ($#argsNames != -1)? join ', ',@argsNames : "";
          $funcArgsTypes = ($#argsTypes != -1)? join ', ',@argsTypes : "";
        } else {
          $funcArgsNames = "";
          $funcArgsTypes = "void";
        }

	my $func = "${funcName}_ptr";
	$args =~ s$(/\*|\*/)$$g; # uncomment names
	print "static ".trim($funcRet)." (*$func)($funcArgsTypes) = NULL;\n";
 	print trim($funcRet)." CL_API_CALL $funcName ($funcArgSig) {\n";
	print "\tif(!$func) $func = getFunction(\"$funcName\");\n";
	print "\treturn (*$func)($funcArgsNames);\n";
 	print "}\n\n";
}

close(CL);
