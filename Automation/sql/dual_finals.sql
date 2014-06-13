SELECT a.week,b.team_name,a.score,c.team_name,d.score,a.score-d.score delta
  from meets a,teams b,teams c,meets d 
 where a.team=b.code 
   and a.opponent=c.code 
   and d.week=a.week
   and d.team=a.opponent
   and a.score>=d.score
 order by week,delta desc
