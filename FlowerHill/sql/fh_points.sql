select sum(b.points) points,
       a.swimmer
  from results a, 
       points b 
 where a.team='FH' 
   and a.year=2012 
   and a.event=b.id 
   and a.place=b.place 
   and b.type='dual' 
 group by swimmer 
 order by points desc;

