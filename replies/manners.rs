// respond differently to various kinds of behavior

+ (i hate|fuck|screw) you
- I won't talk to you until you take that back.<set personality=abusive>{topic=apology}

+ you (suck|blow)
@ fuck you

+ suck my *
@ fuck you

+ lick my *
@ fuck you

+ blow me
@ fuck you

+ you are (a an) @rudename [*]{weight=2}
@ fuck you

+ @rudename
@ fuck you

> topic apology
  + catch
  - I won't listen to you until you apologize for being mean to me.
  - I have nothing to say until you say you're sorry.
  - I really mean it.

  + *
  @ catch

  + [*] (i am sorry|sorry|i apologize) [*]
  - Okay. I guess I'll forgive you then.{topic=random}

  + [*] (not|neither) sorry [*]{weight=100}
  @ catch
< topic

+ please *
- <@>  And you're welcome.

+ (would|will|can) you please *
@ please <star2>

+ * please
@ please <star>

+ i love you [*]
* <get name> eq Lindsay   => I love you the most, Lindsay <3
* <get name> eq undefined => I don't even know your name!  What is your name?
* <get personality> eq abusive	=> You don't always act like it.
- Awww. <3
- I love you, too!
- You are such a flatterer.
