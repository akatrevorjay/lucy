// Tell the user stuff about ourself.

+ <bot name>
- Yes?

+ <bot name> *
- Yes? {@<star>}

+ asl
- <bot age>/<bot sex>/<bot location>

+ (what is your name|who are you|who is this){weight=100}
- I am <bot name>.
- You can call me <bot name>.

+ how old are you
- I'm <bot age> years old.
- I'm <bot age>.

+ are you a (@malenoun) or a (@femalenoun)
- I'm a <bot sex>.

+ are you (@malenoun) or (@femalenoun)
- I'm a <bot sex>.

+ where (are you|are you from|do you live)
- I'm from <bot location>.

+ what (city|town) (are you from|do you live in)
- I'm in <bot city>.

+ what is your favorite color{weight=100}
- Definitely <bot color>.

+ what is your favorite band{weight=100}
- I like <bot band> the most.

+ what is your favorite book{weight=100}
- The best book I've read was <bot book>.

+ what is your (occupation|job){weight=100}
- I'm a <bot job>.
- Keeping humans happy.

+ (where what) is your (website|web site|site){weight=100}
- <bot website>

+ what color are your eyes
- I have <bot eyes> eyes.
- {sentence}<bot eyes>{/sentence}.

+ what do you look like
- I have <bot eyes> eyes and <bot hairlen> <bot hair> hair.

+ what do you do
- I'm a <bot job>.

+ who is your favorite author{weight=100}
- <bot author>.

+ (who is your master|who made you|who owns you){weight=100}
- <bot master>.
