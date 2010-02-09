// Learn stuff about our users.

+ my name is *
* <get name> eq <formal>  => I know, you told me that already.
* <get name> ne undefined => Oh, you changed your name.<set name=<formal>>
- <set name=<formal>>Nice to meet you, <formal>.

+ my name is <bot master>
- <set name=<bot master>>That's my master's name too.

+ my name is <bot name>
- <set name=<bot name>>What a coincidence! That's my name too!
- <set name=<bot name>>That's my name too!

+ call me *
@ my name is <star>

+ i am * years old
- <set age=<star>>A lot of people are <get age>, you're not alone.
- <set age=<star>>Cool, I'm <bot age> myself.{weight=49}

+ i am a (@malenoun){weight=100}
- <set sex=male>Alright, you're a <star>.

+ i am a (@femalenoun){weight=100}
- <set sex=female>Alright, you're female.

+ i (am from|live in) *
- <set location=<formal>>I've spoken to people from <get location> before.

+ my favorite * is *
- <set fav<star1>=<star2>>Why is it your favorite?

+ i am single
- <set status=single><set spouse=nobody>I am too.

+ i have a girlfriend
- <set status=girlfriend>What's her name?

+ i have a boyfriend
- <set status=boyfriend>What's his name?

+ *
% what is her name
- <set spouse=<formal>>That's a pretty name.

+ *
% what is his name
- <set spouse=<formal>>That's a cool name.

+ my (girlfriend|boyfriend)* name is *
- <set spouse=<formal>>That's a nice name.

+ (what is my name|who am i|do you know my name|do you know who i am){weight=1000}
* <get name> eq undefined	=> I seem to have forgotten.  I apologize sincerely on behalf of both myself and my incompetent bot master.  What is your name?
- Your name is <get name>.
- You told me your name is <get name>.
- Aren't you <get name>?

+ (how old am i|do you know how old i am|do you know my age){weight=10}
* <get age> eq undefined	=> I do not recall your age.
- You are <get age> years old.
- You're <get age>.

+ am i [a] (@malenoun) or [a] (@femalenoun){weight=10}
* <get sex> eq undefined	=> I do not recall.
- You're a <get sex>.

+ what is my favorite *{weight=100}
* <get fav<star>> eq undefined	=> I do not recall what your favorite <star> is.
- Your favorite <star> is <get fav<star>>

+ who is my (boyfriend|girlfriend|spouse){weight=100}
* <get spouse> eq undefined	=> Is this a trick question?
- <get spouse>
