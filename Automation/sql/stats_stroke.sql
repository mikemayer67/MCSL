select value,
       gender,
       team,
       avg(points)
  from ( select b.team,
                a.week,
                a.event,
                c.stroke,
                b.gender,
                sum(a.points) points
           from individual_results a,
                swimmers b,
                events c
          where b.ussid=a.swimmer
            and c.number=a.event
         group by team,event,week
       ) d,
       sdif_codes e
 where e.block=12
   and e.code=d.stroke
group by team,stroke,gender
order by stroke,gender,team
