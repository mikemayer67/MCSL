select 
	s.team,
    s.gender,
    cast(s.age as signed) age,
	s.name,
    s.ussid,
    s.birthdate,
    e.n
from 
swimmers s,
( select ussid,count(*) n from
	(
		select swimmer ussid,event,meet from individual_results ir
		union 
		select swimmer1 ussid,event,meet from relay_results rr1 where meet<16
		union 
		select swimmer2 ussid,event,meet from relay_results rr2 where meet<16
		union 
		select swimmer3 ussid,event,meet from relay_results rr3 where meet<16
		union 
		select swimmer4 ussid,event,meet from relay_results rr4 where meet<16
	) ss
  group by ussid
) e
where s.ussid=e.ussid
order by
	s.team,
    s.gender desc,
    age