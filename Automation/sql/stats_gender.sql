select team,
       week,
       gender,
       avg(points)
from (
select c.team_name team,
       a.week,
       b.gender,
       a.event,`
       sum(a.points) points
  from individual_results a,
       swimmers b,
       teams c
  where b.ussid=a.swimmer
    and c.code=b.team
  group by team,event,week,gender
  order by team,event,week,gender
) d
group by team,week,gender
order by team,week,gender