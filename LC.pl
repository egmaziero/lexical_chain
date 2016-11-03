use strict;
use Cwd;
my $dir = getcwd;


my $in;
$in = $ARGV[0];

if (length($in) == 0)
{
	print("Enter the full path to file to be processed as the first argument.\n\n");
	exit -1;
}

#my $in = $dir."/ArtigoWTDA_Agrbalan.txt";

chdir($dir."/wsd");
system("java -jar graph_wsd.jar -in ".$in." -wordnet ".$dir."/resources/WordNet-3.0/dict > ".$dir."/temp/WSDout.txt");
system("java -jar graph_wsd.jar -in ".$dir."/temp/WSDout.txt -wordnet ".$dir."/resources/WordNet-3.0/dict -find > ".$dir."/temp/WSDout2.txt");
chdir($dir);

open(CANDIDATES,">".$dir."/temp/candidates.txt") or die "Error: can't create candidates.txt $!\n";
getNounsSenses();
close(CANDIDATES);
getSensesWD();

#get hypernyms and synonyms
system("python ".$dir."/LC.py");

my @candidates;
my @hypernyms;
my @synonyms;
structureCandidates();

my @LC;
my @items;
my $a = 0;
firstValue($a);
for(my $i=1; $i<=$#candidates; $i++)
{
	my $max = 0;
	my $curr = 0;
	my $index;
	
	my $ident;
	my $syno;
	my $hype;
	my $hypo;
	my $sibli;
	
	for(my $j=0; $j<=$#LC; $j++)
	{
		$curr += identity($i,$j);
		$curr += synonymity($i,$j);
		$curr += hyperonymity($i,$j);
		$curr += hyponymity($i,$j);
		$curr += siblings($i,$j);
		if ($max < $curr)
		{
			$ident = identity($i,$j);
			$syno = synonymity($i,$j);
			$hype = hyperonymity($i,$j);
			$hypo = hyponymity($i,$j);
			$sibli = siblings($i,$j);
			$max = $curr;
			$index = $j;
		}
	}
	if ($max > 0)
	{
		addToPosition($index,$i);
	}
	else
	{
		addNew($i);
	}
}

for(my $o=0; $o<=$#LC;$o++)
{
	my @it = getItems($o);
	foreach(@it)
	{
		print "[".$candidates[$_]->{position}."]".$candidates[$_]->{word}." (".$candidates[$_]->{translation}.") -> ";
	}
	print "\n";
}

unlink("temp/WSDout.txt") or die "Error: can't remove temp file $!\n";
unlink("temp/WSDout2.txt") or die "Error: can't remove temp file $!\n";
unlink("temp/candidates.txt") or die "Error: can't remove temp file $!\n";
unlink("temp/candidatesExpanded.txt") or die "Error: can't remove temp file $!\n";

##########FUNCTIONS
sub addToPosition
{
	my $position = shift;
	my $value = shift;
	
	$LC[$position] = $LC[$position].$value."*";
}

sub addNew
{
	my $value = shift;
	my $last = $#LC;
	my $new = $last+1;
	$LC[$new] = $value."*";
}

sub firstValue
{
	my $value = shift;
	$LC[0] = $value."*";
}

sub getItems
{
	my $position = shift;
	my @partes = split(/\*/,$LC[$position]);
	my @auxList;
	foreach(@partes)
	{
		if ($_ ne "")
		{
			push(@auxList,$_);
		}
	}
	return @auxList;
}

sub identity
{
	my $i = shift;
	my $j = shift;
	my @items = getItems($j);
	foreach(@items)
	{
		if ($candidates[$i]->{translation} eq $candidates[$_]->{translation})
		{
			return 1;
		}
	}
	return 0;
}

sub hyperonymity
{
	my $i = shift;
	my $j = shift;
	my @items = getItems($j);
	my @syno1 = @{$candidates[$i]->{hyperonyms}};
	
	foreach(@items)
	{
		my @syno2 = @{$candidates[$_]->{synonyms}};
		foreach(@syno1)
		{
			my $s1 = trim($_);
			foreach(@syno2)
			{
				my $s2 = trim($_);
				if ($s1 eq $s2)
				{
					return 0.5;
				}
			}
		}
	}
	return 0;
}
sub hyponymity
{
	my $i = shift;
	my $j = shift;
	my @items = getItems($j);
	my @syno1 = @{$candidates[$i]->{synonyms}};
	
	foreach(@items)
	{
		my @syno2 = @{$candidates[$_]->{hyperonyms}};
		foreach(@syno1)
		{
			my $s1 = trim($_);
			foreach(@syno2)
			{
				my $s2 = trim($_);
				if ($s1 eq $s2)
				{
					return 0.5;
				}
			}
		}
	}
	return 0;
}

sub synonymity
{
	my $i = shift;
	my $j = shift;
	my @items = getItems($j);
	my @syno1 = @{$candidates[$i]->{synonyms}};
	
	foreach(@items)
	{
		my @syno2 = @{$candidates[$_]->{synonyms}};
		foreach(@syno1)
		{
			my $s1 = trim($_);
			foreach(@syno2)
			{
				my $s2 = trim($_);
				if ($s1 eq $s2)
				{
					return 0.8;
				}
			}
		}
	}
	return 0;
}

sub siblings
{
	my $i = shift;
	my $j = shift;
	my @items = getItems($j);
	my @syno1 = @{$candidates[$i]->{hyperonyms}};
	
	foreach(@items)
	{
		my @syno2 = @{$candidates[$_]->{hyperonyms}};
		foreach(@syno1)
		{
			my $s1 = trim($_);
			foreach(@syno2)
			{
				my $s2 = trim($_);
				if ($s1 eq $s2)
				{
					return 0.3;
				}
			}
		}
	}
	return 0;
}


sub structureCandidates
{
	open(IN,"<temp/candidatesExpanded.txt") or die "Error: can't open candidates expanded $!\n";
	my @cands = <IN>;
	close(IN);
	
	for(my $i=0; $i<=$#cands; $i++)
	{
		my @parts = split(/\*/,$cands[$i]);
		
		my @translation = split(/\./,$parts[2]);
		if ($translation[2] <= 9){$translation[2] = "0".$translation[2];}
		my @hypernyms;
		my @synonyms;
		
		$candidates[$i] = 
		{
			position => $parts[0],
			word => $parts[1],
			translation => $translation[0].".".$translation[1].".".$translation[2],
			hyperonyms => [@hypernyms],
			synonyms => [@synonyms],
		}; 

		
		my @hypers = split(/Synset\(\'/,$parts[3]);
		for(my $j=1; $j<=$#hypers; $j++)
		{
			$hypers[$j] =~ s/\'\)//gi;
			push(@ { $candidates[$i]->{hyperonyms} },$hypers[$j]);
		}
		my @synos = split(/Synset\(\'/,$parts[4]);
		for(my $j=1; $j<=$#synos; $j++)
		{
			$synos[$j] =~ s/\'\)//gi;
			push(@ { $candidates[$i]->{synonyms} },trim($synos[$j]));
		}
		#adjust n.1 to n.01 to be equal to the format returned by wordnet
	}
}


sub getSensesWD
{
	open(OUT,"<temp/WSDout2.txt") or die "Error openning WSDout2.txt $!\n";
	my @senses = <OUT>;
	close(OUT);
	
	open(OUT,"<temp/candidates.txt") or die "Error openning WSDout2.txt $!\n";
	my @lines = <OUT>;
	close(OUT);
	
	my @tokens;
	open(OUT,">temp/candidates.txt") or die "Error creating output.txt $!\n";
	foreach(@lines)
	{
		my @parts = split(/\*/,$_);
		if ($senses[$parts[0]] =~ /(.*?)\<(.*?)\.(.*?)\.(.*?)\>/)
		{
			print OUT $parts[0]."*".$1."*".$2."*".$3."*".$4."\n";
		}
		else
		{
			print OUT $parts[0]."*".$parts[1]."*np*np*np\n";
		}
	}
	close(OUT);
	
}

sub getNounsSenses
{
	open(OUT,"<temp/WSDout.txt") or die "Error openning WSDout.txt $!\n";
	my @lines = <OUT>;
	close(OUT);
	my @N;
	my @NP;
	
	my @tokens;
	foreach(@lines)
	{
		push(@tokens,split(/\> /,trim($_)));
	}
	
	my $word;
	my $sense;
	my @translations;
	my $translation;
	my $index = 0;
	foreach(@tokens)
	{
		my @parts = split(/_/,$_);
		if ($parts[0] =~ /\<N$/)
		{
			my @parts2 = split(/\</,$parts[0]);
			$word = $parts2[0];
			$sense = $parts[1];
			if ($sense eq ">")
			{
				$sense = "np";
				$translation
			}
			else
			{
				@translations = split(/,/,$parts[2]);
				$translation = trim($translations[0]);
			}
			print CANDIDATES $index."*".$word."*".$sense."*".$translation."\n";	
		}
		elsif ($parts[0] =~ /\<NP$/) # and the caso of compound nouns
		{
			my @parts2 = split(/\</,$parts[0]);
			$word = $parts2[0];
			$sense = "np";
			$translation = "np";
			print CANDIDATES $index."*".$word."*".$sense."*".$translation."\n";
		}
		$index++;
	}
}



sub trim($){
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}