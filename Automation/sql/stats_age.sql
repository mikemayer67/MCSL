select team,age,sum(d.points),avg(d.points),count(d.points)
from (
select b.team,a.week,a.event,c.age,sum(a.points) points
  from individual_results a,
       swimmers b,
       events c
  where b.ussid=a.swimmer
    and c.number=a.event
  group by team,event,week,age
  order by team,event,week,age
) d
group by team,age
order by team,age