select R.meet,
       S.age,
       S.gender,
       S.name,
       R.event,
       A.text event_age,
       concat(E.distance,'M'),
       SDIF.value as stroke,
       R.DQ,
       R.time,
       R.place
from   individual_results R,
       swimmers S,
       events E,
       sdif_codes SDIF,
       age_codes A,
       age_groups AG,
       age_codes AX
where  R.swimmer=S.USSID
  and  S.team='PVFH'
  and  R.meet=15
  and  E.meet_type='dual'
  and  E.number=R.event
  and  SDIF.block=12
  and  SDIF.code=E.stroke
  and  A.code=E.age
  and  AG.age=S.age
  and  AX.code=A.code
order by 
       AX.order,
       S.gender, 
       S.name,
       R.event;