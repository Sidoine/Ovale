=c
--<private-static-properties>
--</private-static-properties>

--<private-static-methods>
--</private-static-methods>

--<public-static-properties>
--</public-static-properties>

--<public-static-methods>
--</public-static-methods>

--<public-methods>
--</public-methods>

--<public-properties>
--</public-properties>
=cut

$p{Skada}{current} = true;
$p{Skada}{total} = true;
$m{Skada}{NewModule} = true;
$m{Skada}{RemoveMode} = true;
$m{Skada}{get_player} = true;
$m{Skada}{AddMode} = true;

$p{Recount}{db} = true;
$p{Recount}{db2} = true;
$m{Recount}{AddModeTooltip} = true;
$m{Recount}{AddAmount} = true;
$m{Recount}{AddSortedTooltipData} = true;

$m{AceGUI}{RegisterWidgetType} = true;
$m{AceGUI}{RegisterAsContainer} = true;
$m{AceGUI}{ClearFocus} = true;

$m{DEFAULT_CHAT_FRAME}{AddMessage} = true;

$m{LRC}{GetRange} = true;

$m{AceConfigDialog}{Open} = true;
$m{AceConfigDialog}{AddToBlizOptions} = true;
$m{AceConfigDialog}{SetDefaultSize} = true;

$m{Masque}{Group} = true;

$m{AceConfig}{RegisterOptionsTable} = true;

$m{GameTooltip}{SetText} = true;
$m{GameTooltip}{ClearLines} = true;
$m{GameTooltip}{SetOwner} = true;
$m{GameTooltip}{AddDoubleLine} = true;
$m{GameTooltip}{Show} = true;
$m{GameTooltip}{Hide} = true;
$m{GameTooltip}{AddLine} = true;

opendir(DIR, ".");
while (defined($r = readdir(DIR)))
{
	if ($r =~ m/(Ovale.*)\.lua$/)
	{
		my $class = $1;
		open(F, "<", $r);
		undef $/;
		my $content = <F>;
		close(F);
		
		my %psp = {};
		my %psm = {};
		my %pp = {};
		my %pm = {};
		
		if ($content =~ m/--inherits (\w+)/)
		{
			if ($1 eq 'ActionButtonTemplate')
			{
				$m{$class}{Show} = true;
				$m{$class}{Hide} = true;
				$m{$class}{SetChecked} = true;
				$m{$class}{CreateFontString} = true;
				$m{$class}{RegisterForClicks} = true;
				$m{$class}{EnableMouse} = true;
				$m{$class}{GetName} = true;
			}
			if ($1 eq 'Frame')
			{
				$m{$class}{StartMoving} = true;
				$m{$class}{StopMovingOrSizing} = true;
				$m{$class}{GetLeft} = true;
				$m{$class}{GetTop} = true;
			}
		}
		
		if ($content =~ m/$class\s*=\s*LibStub/)
		{
			$pm{'RegisterEvent'} = true;
			$pm{'UnregisterEvent'} = true;
			$m{$class}{Print} = true;
		}
		
		if ($content =~ m/<private-static-properties>(.*)<\/private-static-properties>/s)
		{
			my $psp = $1;
			while ($psp =~ m/local (\w+)\s*=/g)
			{
				$psp{$1} = true;
			}
		}
		
		if ($content =~ m/<private-static-methods>(.*)<\/private-static-methods>/s)
		{
			my $psm = $1;
			while ($psm =~ m/local function (\w+)\s*=/g)
			{
				$psm{$1} = true;
			}
		}
		
		if ($content =~ m/<public-static-properties>(.*)<\/public-static-properties>/s)
		{
			my $sp = $1;
			while ($sp =~ m/${class}\.(\w+)\s*=/g)
			{
				$sp{$class}{$1} = true;
			}
		}
		
		if ($content =~ m/<public-static-methods>(.*)<\/public-static-methods>/s)
		{
			my $sm = $1;
			while ($sm =~ m/function\s+$class:(\w+)\s*\(/g)
			{
				$sm{$class}{$1} = true;
				delete $m{$class}{$1}
			}
		}
		
		if ($content =~ m/<public-methods>(.*)<\/public-methods>/s)
		{
			my $m = $1;
			while ($m =~ m/local function (\w+)\(self/g)
			{
				$m{$class}{$1} = true;
				delete $sm{$class}{$1}
			}
		}
		
		if ($content =~ m/<public-properties>(.*)<\/public-properties>/s)
		{
			my $p = $1;
			while ($p =~ m/self\.(\w+)/g)
			{
				$p{$class}{$1} = true;
			}
		}
		
		while ($content =~ m/\b([A-Z]\w+)\.(\w+)/g)
		{
			unless ($sp{$1}{$2} or $p{$1}{$2})
			{
				$sp{$1}{$2} = $class;
			}
		}
		
		while ($content =~ m/\b([A-Z]\w+)\:(\w+)/g)
		{
			unless ($sm{$1}{$2} or $m{$1}{$2})
			{
				$sm{$1}{$2} = $class;
			}
		}
		
		while ($content =~ m/self\.([a-z]\w*)/g)
		{
			#if ($class eq 'OvaleSwing')
			#{
			#	print $1," ",$sp{$class}{$1}," ",$pp{$1}, " ", $p{$class}{$1},"\n";
			#}
			unless ($sp{$class}{$1} eq true or $pp{$1} eq true or $p{$class}{$1} eq true)
			{
				print "La classe $class ne contient pas la propriété $1\n";
			}
		}
		
		while ($content =~ m/self\:(\w+)/g)
		{
			unless ($sm{$class}{$1} eq true or $pm{$1} eq true or $m{$class}{$1} eq true)
			{
				print "La classe $class ne contient pas la méthode $1\n";
			}
		}
	}
}

for my $class (keys %sm)
{
	for my $method (keys %{$sm{$class}})
	{
		unless ($sm{$class}{$method} eq true)
		{
			print "public static $class:$method $sm{$class}{$method}\n";
		}
	}
}

for my $class (keys %m)
{
	for my $method (keys %{$m{$class}})
	{
		unless ($m{$class}{$method} eq true)
		{
			print "public $class:$method $m{$class}{$method}\n";
		}
	}
}

for my $class (keys %sp)
{
	for my $prop (keys %{$sp{$class}})
	{
		unless ($sp{$class}{$prop} eq true)
		{
			print "public static $class.$prop $sp{$class}{$prop}\n";
		}
	}
}

