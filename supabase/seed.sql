insert into public.missions (id,title,description,category,mood_tags,duration_minutes,budget,difficulty,xp_reward,environment,instructions)
select 'seed-' || lpad(n::text,2,'0'),
       (array['Make a mini playlist','Take a mindful walk','Sketch something nearby','Send a kind message','Learn a new word','Try a stretch break','Spot cloud shapes','Make a simple snack','Find five patterns','Dance to one song'])[1 + ((n-1)%10)],
       'A safe, achievable mini adventure. Make it your own and enjoy the moment.',
       (array['Social','Creative','Adventure','Learning','Fitness','Entertainment'])[1 + ((n-1)%6)],
       (array['Happy','Bored','Stressed','Adventurous','Creative','Lazy']),
       (array[5,15,30,60])[1 + ((n-1)%4)],
       (array[0,0,100,300])[1 + ((n-1)%4)],
       'Easy', 15 + ((n-1)%4)*5,
       (array['Indoor','Outdoor','Both'])[1 + ((n-1)%3)],
       'Choose a comfortable, safe setting. Stop or adapt whenever you need.'
from generate_series(1,40) as n
on conflict (id) do nothing;

insert into public.achievements(id,title,description,xp_required) values
 ('first-step','First Step','Complete your first mission.',15),
 ('curious-mind','Curious Mind','Earn 100 XP.',100),
 ('on-a-roll','On a Roll','Earn 300 XP.',300)
on conflict (id) do nothing;
