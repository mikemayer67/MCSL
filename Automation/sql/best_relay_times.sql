select 
	rr.event,
    s.value gender,
    ac.text age,
    concat(e.distance,'M') distance,
    sc.value stroke,
	concat(rr.team,'-',rr.relay_team) team,
    min(rr.time) seed_time
from 
	relay_results rr,
    events e,
    sdif_codes s,
    age_codes ac,
    sdif_codes sc
where
	rr.dq='N'
and rr.meet<16
and e.meet_type='dual'
and e.number=rr.event
and s.block=10
and s.code=e.gender
and ac.code=e.age
and sc.block=12
and sc.code=e.stroke
group by
	rr.event,
    rr.team,
    rr.relay_team
order by 
	rr.event,
    rr.time,
    rr.team,
    rr.relay_team