select b.name,',',concat(a.swimmer,' (',a.team,')'),',',a.time  from results a,events b where a.event=b.id and team in (select id from teams where division='N') order by event,time;
