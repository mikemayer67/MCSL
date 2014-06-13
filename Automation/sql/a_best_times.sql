select R.event,
       S.team,
       S.name,
       S.age,
       min(R.time) best_time,
       R.swimmer
  from individual_results R,
       swimmers S
 where S.ussid=R.swimmer
 group by team,swimmer,event
 order by event,best_time,team,swimmer