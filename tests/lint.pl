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

--<state-properties>
--</state-properties>

--<state-methods>
--</state-methods>
=cut

$sm{"AceAddon-3.0"}{GetModule} = true;
$sm{"AceAddon-3.0"}{GetName} = true;
$sm{"AceAddon-3.0"}{NewModule} = true;
$sm{"AceAddon-3.0"}{SetDefaultModulePrototype} = true;

$m{AceConfig}{RegisterOptionsTable} = true;

$m{AceConfigDialog}{AddToBlizOptions} = true;
$m{AceConfigDialog}{Close} = true;
$m{AceConfigDialog}{Open} = true;
$sp{AceConfigDialog}{OpenFrames} = true;
$m{AceConfigDialog}{SetDefaultSize} = true;

$sm{"AceConsole-3.0"}{Print} = true;
$sm{"AceConsole-3.0"}{Printf} = true;

$sm{"AceEvent-3.0"}{RegisterEvent} = true;
$sm{"AceEvent-3.0"}{RegisterMessage} = true;
$sm{"AceEvent-3.0"}{SendMessage} = true;
$sm{"AceEvent-3.0"}{UnregisterEvent} = true;
$sm{"AceEvent-3.0"}{UnregisterMessage} = true;

$m{AceGUI}{ClearFocus} = true;
$m{AceGUI}{Create} = true;
$m{AceGUI}{RegisterAsContainer} = true;
$m{AceGUI}{RegisterWidgetType} = true;

$m{AceLocale}{GetLocale} = true;

$sm{"AceSerializer-3.0"}{Deserialize} = true;
$sm{"AceSerializer-3.0"}{Serialize} = true;

$sm{"AceTimer-3.0"}{CancelTimer} = true;
$sm{"AceTimer-3.0"}{ScheduleRepeatingTimer} = true;
$sm{"AceTimer-3.0"}{ScheduleTimer} = true;

$m{ActionButtonTemplate}{CreateFontString} = true;
$m{ActionButtonTemplate}{EnableMouse} = true;
$m{ActionButtonTemplate}{GetName} = true;
$m{ActionButtonTemplate}{Hide} = true;
$m{ActionButtonTemplate}{RegisterForClicks} = true;
$m{ActionButtonTemplate}{SetAttribute} = true;
$m{ActionButtonTemplate}{SetChecked} = true;
$m{ActionButtonTemplate}{SetScript} = true;
$m{ActionButtonTemplate}{Show} = true;

$m{DEFAULT_CHAT_FRAME}{AddMessage} = true;

$m{Frame}{GetCenter} = true;
$m{Frame}{GetNumPoints} = true;
$m{Frame}{GetPoint} = true;
$m{Frame}{GetParent} = true;
$m{Frame}{SetAttribute} = true;
$m{Frame}{SetScript} = true;
$m{Frame}{StartMoving} = true;
$m{Frame}{StopMovingOrSizing} = true;

$m{GameTooltip}{AddDoubleLine} = true;
$m{GameTooltip}{AddLine} = true;
$m{GameTooltip}{ClearLines} = true;
$m{GameTooltip}{Hide} = true;
$m{GameTooltip}{SetOwner} = true;
$m{GameTooltip}{SetText} = true;
$m{GameTooltip}{Show} = true;

# Hack to silence warnings about LICENSE.txt.
$sp{LICENSE}{txt} = true;

$m{LibBabbleCreatureType}{GetLookupTable} = true;

$m{LibDataBroker}{NewDataObject} = true;

$m{LibDBIcon}{Hide} = true;
$m{LibDBIcon}{Refresh} = true;
$m{LibDBIcon}{Register} = true;
$m{LibDBIcon}{Show} = true;

$m{LibDispellable}{IsEnrageEffect} = true;

$m{LibDualSpec}{EnhanceDatabase} = true;
$m{LibDualSpec}{EnhanceOptions} = true;

$m{LibRangeCheck}{GetRange} = true;

$m{LibStub}{GetLibrary} = true;

$m{LibTextDump}{New} = true;

$m{Masque}{Group} = true;

$m{Recount}{AddAmount} = true;
$m{Recount}{AddModeTooltip} = true;
$m{Recount}{AddSortedTooltipData} = true;
$p{Recount}{db2} = true;
$p{Recount}{db} = true;

$m{Skada}{AddMode} = true;
$m{Skada}{NewModule} = true;
$m{Skada}{RemoveMode} = true;
$m{Skada}{get_player} = true;
$p{Skada}{current} = true;
$p{Skada}{total} = true;

$sp{SpellFlashCore}{FlashAction} = true;
$sp{SpellFlashCore}{FlashForm} = true;
$sp{SpellFlashCore}{FlashItem} = true;
$sp{SpellFlashCore}{FlashPet} = true;

$sp{Ovale}{OvaleLexer} = true;
$sp{Ovale}{OvalePool} = true;
$sp{Ovale}{OvalePoolGC} = true;
$sp{Ovale}{OvalePoolRefCount} = true;
$sp{Ovale}{OvaleQueue} = true;
$sp{Ovale}{OvaleSimulationCraft} = true;
$sp{Ovale}{OvaleSkada} = true;
$sp{Ovale}{OvaleTimeSpan} = true;
$sp{Ovale}{Profiler} = true;

$sm{OvaleBestAction}{Compute} = true;

$sm{OvaleQueue}{NewQueue} = true;
$sp{OvaleQueue}{Front} = true;
$sp{OvaleQueue}{FrontToBackIterator} = true;
$sp{OvaleQueue}{InsertBack} = true;
$sp{OvaleQueue}{InsertFront} = true;
$sp{OvaleQueue}{NewDeque} = true;
$sp{OvaleQueue}{RemoveFront} = true;

# WoWMock configuration table.
$sp{WOWMOCK_CONFIG}{addonName} = true;
$sp{WOWMOCK_CONFIG}{class} = true;
$sp{WOWMOCK_CONFIG}{guid} = true;
$sp{WOWMOCK_CONFIG}{level} = true;
$sp{WOWMOCK_CONFIG}{name} = true;
$sp{WOWMOCK_CONFIG}{specialization} = true;

# Ovale module prototype.
$sm{"modulePrototype"}{Error} = true;
$sm{"modulePrototype"}{Log} = true;
$sm{"modulePrototype"}{Print} = true;
# Added by OvaleDebug.
$sm{"OvaleDebugPrototype"}{Debug} = true;
# Added by OvaleProfiler.
$sm{"OvaleProfilerPrototype"}{StartProfiling} = true;
$sm{"OvaleProfilerPrototype"}{StopProfiling} = true;

$classname{Localization} = "Localization";
$classname{Ovale} = "Ovale";
$classname{WoWMock} = "WoWMock";

sub ParseDirectory
{
	my $dh = shift;
	my $dir = shift;
	while (defined($r = readdir($dh)))
	{
		if ($r =~ m/(.*)\.lua$/)
		{
			my $global_result = `luac5.1 -l -p $dir/$r | lua5.1 globals.lua $dir/$r | grep GETGLOBAL`;
			if ($global_result ne "")
			{
				print "$dir/$r\n";
				print "$global_result";
			}
			my $class = "$1";
			if ($class =~ m/^([A-Z].*)/)
			{
				$class = $classname{$1};
				if ($class eq "")
				{
					$class = "Ovale$1";
				}
			}
			open(F, "<", "$dir/$r");
			undef $/;
			my $content = <F>;
			close(F);

			my %psp = {};
			my %psm = {};
			my %pp = {};
			my %pm = {};

			if ($content =~ m/--<class name="(\w+)"\s*\/>/)
			{
				$class = $1;
			}

			if ($content =~ m/--<class name="(\w+)"\s+inherits="(\w+)"\s*\/>/)
			{
				$class = $1;
				my $parent = $2;
				for my $prop (keys %{$sp{$parent}})
				{
					$sp{$class}{$prop} = $sp{$parent}{$prop}
				}
				for my $method (keys %{$sm{$parent}})
				{
					$sm{$class}{$method} = $sm{$parent}{$method}
				}
				for my $method (keys %{$m{$parent}})
				{
					$m{$class}{$method} = $m{$parent}{$method}
				}
			}

			if ($content =~ m/$class\s*=\s*LibStub\("([^)]+)"\):NewAddon\(([^)]+)\)/)
			{
				my $factory = $1;
				my $mixins = $2;
				for my $method (keys %{$sp{$factory}})
				{
					$sp{$class}{$method} = $sp{$factory}{$method}
				}
				for my $method (keys %{$sm{$factory}})
				{
					$sm{$class}{$method} = $sm{$factory}{$method}
				}
				for my $method (keys %{$m{$factory}})
				{
					$m{$class}{$method} = $m{$factory}{$method}
				}
				while ($mixins =~ m/"([^",]+)"/g)
				{
					my $parent = $1;
					if ($parent ne $class)
					{
						for my $method (keys %{$sp{$parent}})
						{
							$sp{$class}{$method} = $sp{$parent}{$method}
						}
						for my $method (keys %{$sm{$parent}})
						{
							$sm{$class}{$method} = $sm{$parent}{$method}
						}
						for my $method (keys %{$m{$parent}})
						{
							$m{$class}{$method} = $m{$parent}{$method}
						}
					}
				}
			}

			if ($content =~ m/$class\s*=\s*([^:]+):NewModule\(([^)]+)\)/)
			{
				my $parent = $1;
				my $mixins = $2;
				$sp{$parent}{$class} = true;
				my $factory = "AceAddon-3.0";
				for my $method (keys %{$sp{$factory}})
				{
					$sp{$class}{$method} = $sp{$factory}{$method}
				}
				for my $method (keys %{$sm{$factory}})
				{
					$sm{$class}{$method} = $sm{$factory}{$method}
				}
				for my $method (keys %{$m{$factory}})
				{
					$m{$class}{$method} = $m{$factory}{$method}
				}
				my $prototype = "modulePrototype";
				for my $method (keys %{$sp{$prototype}})
				{
					$sp{$class}{$method} = $sp{$prototype}{$method}
				}
				for my $method (keys %{$sm{$prototype}})
				{
					$sm{$class}{$method} = $sm{$prototype}{$method}
				}
				for my $method (keys %{$m{$prototype}})
				{
					$m{$class}{$method} = $m{$prototype}{$method}
				}
				while ($mixins =~ m/"([^",]+)"/g)
				{
					my $parent = $1;
					if ($parent ne $class)
					{
						for my $method (keys %{$sp{$parent}})
						{
							$sp{$class}{$method} = $sp{$parent}{$method}
						}
						for my $method (keys %{$sm{$parent}})
						{
							$sm{$class}{$method} = $sm{$parent}{$method}
						}
						for my $method (keys %{$m{$parent}})
						{
							$m{$class}{$method} = $m{$parent}{$method}
						}
					}
				}
			}

			if ($content =~ m/OvaleDebug:RegisterDebugging\(([^,]+).*\)/)
			{
				my $prototype = "OvaleDebugPrototype";
				for my $method (keys %{$sp{$prototype}})
				{
					$sp{$class}{$method} = $sp{$prototype}{$method}
				}
				for my $method (keys %{$sm{$prototype}})
				{
					$sm{$class}{$method} = $sm{$prototype}{$method}
				}
				for my $method (keys %{$m{$prototype}})
				{
					$m{$class}{$method} = $m{$prototype}{$method}
				}
			}

			if ($content =~ m/OvaleProfiler:RegisterProfiling\(([^,]+).*\)/)
			{
				my $prototype = "OvaleProfilerPrototype";
				for my $method (keys %{$sp{$prototype}})
				{
					$sp{$class}{$method} = $sp{$prototype}{$method}
				}
				for my $method (keys %{$sm{$prototype}})
				{
					$sm{$class}{$method} = $sm{$prototype}{$method}
				}
				for my $method (keys %{$m{$prototype}})
				{
					$m{$class}{$method} = $m{$prototype}{$method}
				}
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
				while ($psm =~ m/(\w+)\s*=\s*function\s*\(/g)
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
				while ($sm =~ m/function\s+${class}[.:](\w+)\s*\(/g)
				{
					$sm{$class}{$1} = true;
					delete $m{$class}{$1};
					# All public static methods are also public static properties.
					$sp{$class}{$1} = true;
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

			if ($content =~ m/<state-properties>(.*)<\/state-properties>/s)
			{
				my $p = $1;
				while ($p =~ m/statePrototype\.(\w+)/g)
				{
					$smp{$1} = true;
				}
			}

			if ($content =~ m/<state-methods>(.*)<\/state-methods>/s)
			{
				my $p = $1;
				while ($p =~ m/statePrototype\.(\w+)/g)
				{
					$smm{$1} = true;
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

			while ($content =~ m/\bstate\.(\w+)/g)
			{
				unless ($smp{$1})
				{
					$smp{$1} = $class;
				}
			}

			while ($content =~ m/\bstate\:(\w+)/g)
			{
				unless ($smm{$1})
				{
					$smm{$1} = $class;
				}
			}

			while ($content =~ m/self\.([a-z]\w*)/g)
			{
				unless ($sp{$class}{$1} eq true or $pp{$1} eq true or $p{$class}{$1} eq true)
				{
					print "The class $class does not contain the property $1\n";
				}
			}

			while ($content =~ m/self\:(\w+)/g)
			{
				unless ($sm{$class}{$1} eq true or $pm{$1} eq true or $m{$class}{$1} eq true)
				{
					print "The class $class does not contain the method $1\n";
				}
			}
		}
	}
}

my @directories = ("..", "../scripts");
while ($dir = shift @directories)
{
	opendir(my $dh, $dir);
	ParseDirectory($dh, $dir);
	closedir($dh);
}

for my $class (keys %sm)
{
	for my $method (keys %{$sm{$class}})
	{
		unless ($sm{$class}{$method} eq true)
		{
			print "public static $class:$method used in $sm{$class}{$method}\n";
		}
	}
}

for my $class (keys %m)
{
	for my $method (keys %{$m{$class}})
	{
		unless ($m{$class}{$method} eq true)
		{
			print "public $class:$method used in $m{$class}{$method}\n";
		}
	}
}

for my $class (keys %sp)
{
	for my $prop (keys %{$sp{$class}})
	{
		unless ($sp{$class}{$prop} eq true)
		{
			print "public static $class.$prop used in $sp{$class}{$prop}\n";
		}
	}
}

for my $prop (keys %smp)
{
	unless ($smp{$prop} eq true)
	{
		print "state machine property state.$prop used in $smp{$prop}\n";
	}
}

for my $method (keys %smm)
{
	unless ($smm{$method} eq true)
	{
		print "state machine method state:$method used in $smm{$method}\n";
	}
}
