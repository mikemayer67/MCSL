SELECT
  e.number,
  e.age,
  e.gender,
  e.distance,
  c.value,
  s.name,
  s.team,
  min(ir.time) best_time
FROM 
  divo_2016.individual_results as ir,
  swimmers s,
  events e,
  sdif_codes c
where
  s.team = 'PVMB' and
  s.ussid = ir.swimmer and
  ir.event = e.number and
  ir.time is not null and
  e.meet_type = 'dual' and
  c.block=12 and
  c.code=e.stroke
group by
  ir.event,
  ir.swimmer
order by
  ir.event,
  time
;
  