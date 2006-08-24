package Acme::Magic8Ball;

use Exporter;
use base qw(Exporter);
use vars qw($VERSION @EXPORT_OK);



# are we ever going to need enhancements? Apparently yes :(
$VERSION   = "1.1"; 
@EXPORT_OK = qw(ask);

=head1 NAME

Acme::Magic8Ball - ask the Magic 8 Ball a question

=head1 SYNOPSIS

    use Acme::Magic8Ball qw(ask);
    my $reply = ask("Is this module any use whatsoever?");

=head1 DESCRIPTION

This is an almost utterly pointless module. But I needed it. So there.

=head1 METHODS

=head2 ask <question>

Ask and ye shall receive!

=cut
    
sub ask {
    my $question = shift || return "You must ask a question!";

    my $pos = tell DATA;
    my @answers = map { chomp; $_ } <DATA>;
    seek DATA, $pos,0;
    return $answers[rand($#answers)];
}

=head1 AUTHOR

Simon Wistow <simon@thegestalt.org>

=head1 COPYING

Copyright 2005, Simon Wistow

Distributed under the same terms as Perl itself.

=head1 SEE ALSO

The 8 Ball FAQ              - http://8ball.ofb.net/faq.html

Mattel (who own the 8 Ball) - http://www.mattel.com         

=cut




__DATA__
Signs point to yes.
Yes.
Reply hazy, try again.
Without a doubt.
My sources say no.
As I see it, yes.
You may rely on it.
Concentrate and ask again.
Outlook not so good.
It is decidedly so.
Better not tell you now.
Very doubtful.
Yes - definitely.
It is certain.
Cannot predict now.
Most likely.
Ask again later.
My reply is no.
Outlook good.
Don't count on it.
