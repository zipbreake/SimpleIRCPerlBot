#!/usr/bin/perl
##################################################################
#                                                                #
#  SimpleIRCPerlBot 2001-2009 Javier Fernández Viña (ZipBreake)  #
#                javier@jfv.es - http://jfv.es                   #
#                                                                #
##################################################################
use IO::Socket;
require "bot.conf";

##################################################################
#                    COMANDOS IMPLEMENTADOS                      #
##################################################################

$priv_cmds  = \%comandos;
$priv_cmds -> {"HELP"} = "do_help";


$chan_cmds  = \%chancmds;
$chan_cmds -> {"!HELP"} = "do_chanhelp";

##################################################################
#              RUTINAS GENERALES (conexión....)                  #
##################################################################

$socket = IO::Socket::INET->new(Proto => "tcp", PeerAddr => $servidor, PeerPort => $puerto);
$socket -> autoflush(1);
print "Conectado Bot\n";
if (fork()) { exit; }

$entrabot = 0;
while (($linea = <$socket> ))
{
	#print $linea;
	if ( $entrabot == 0 )
	{
		sendcmd("NICK $botnick:$botclave\n");
		sendcmd("USER $botident - - :$botinfo\n");
		$entrabot++;
	}
	if ( $linea=~/PING/i )
	{
		$_ = $linea;
		tr/I/O/;
		print $socket "$_\n";
	}

	$_ = $linea;
	$_ =~ tr/A-Z/a-z/;
	$root =~ tr/A-Z/a-z/;
	chop($_);
	s/://;
	@recibido = split(/:/, $_);
	@temp = split(/ /, $recibido[0]);

	if ( ( $temp[1] =~ /privmsg/ ) && ( $temp[2] =~ /#/i ))
	{
		@nick = split(/\!/, $temp[0]);
		chop($recibido[1]);
		@cmds = split(/ /, $recibido[1]);
		&chan_parser($nick[0], @cmds);
	}

	if ( ( $temp[1] =~ /privmsg/ ) && ( $temp[2] =~ /$botnick/i ))
	{
		@nick = split(/\!/, $temp[0]);
		#print "Recivo <<< $nick[0] -> $recibido[1]\n";
		chop($recibido[1]);
		@cmds = split(/ /, $recibido[1]);
		&bot_parser($nick[0], @cmds);
	}

	if ($linea=~/251/i && $entrabot == 1)
	{
		sendcmd("MODE $botnick +i\n");
		sendcmd("JOIN $canal\n");
		$entrabot++;
	}
}

# Parseo del PRIVMSG
sub bot_parser
{
	$ejecutar = uc ( $cmds[0] );
	$funcion_bot = $comandos{"$ejecutar"};
	if ( $funcion_bot ) { &$funcion_bot($nick[0], @cmds); }
	return;
}

sub chan_parser
{
	$ejecutar = uc ( $cmds[0] );
	$funcion_chan = $chancmds{"$ejecutar"};
	if ( $funcion_chan ) { &$funcion_chan($nick[0], @cmds); }
	return;
}

##################################################################
#                 RUTINAS DE HABLADO DEL BOTIJO.                 #
##################################################################

sub sendcmd
{
   my ($text) = (shift);
   print $socket "$text\n";
   return;
}

sub privmsg
{
   my ($nick,$text) = (shift, shift);
   print $socket "PRIVMSG $nick :$text\n";
   return;
}

sub notice
{
   my ($nick,$text) = (shift, shift);
   print $socket "NOTICE $nick :$text\n";
   return;
}

##################################################################
#                 COMANDOS DEL BOT EN CANALES                    #
##################################################################
sub do_chanhelp
{
	open(HELP,"help/chan/main.help");
	@ayudas = <HELP>;
	foreach $ayuda (@ayudas) {
		notice($nick[0], "$ayuda");
	}
	close(HELP);
	return;
}

##################################################################
#                 COMANDOS DEL BOT POR PRIVADO                   #
##################################################################
sub do_help
{
	if (!$cmds[1])
	{
		open(HELP,"help/main.help");
		@ayudas = <HELP>;
		foreach $ayuda (@ayudas)
		{
			privmsg($nick[0], "$ayuda");
		}
		close(HELP);

		if (($nick[0] eq $root))
		{
			open(HELP,"help/help.root");
			@ayudas = <HELP>;
			foreach $ayuda (@ayudas)
			{
				privmsg($nick[0], "$ayuda");
			}
			close(HELP);
		}
	} elsif ($cmds[1]) {
		open(HELP,"help/$cmds[1].help");
		@ayudas = <HELP>;
		foreach $ayuda (@ayudas)
		{
			privmsg($nick[0], "$ayuda");
		}
		close(HELP);
	} else {
		privmsg($nick[0], "No hay ayuda disponible para 12$cmds[1]");
	}
	return;
}

##################################################################
#                  COMANDOS DEL ROOT DEL BOT                     #
##################################################################
