begin;

create temporary table r (
       team_id	 integer,
       div	 	 integer,
       year	 	 integer,
       str	 	 float,
       ofs	 	 float,
       dfs	 	 float,
       sos	 	 float
);

insert into r
(team_id,div,year,str,ofs,dfs,sos)
(
select
t.team_id,
t.div_id as div,
sf.year,
(sf.strength*o.exp_factor/d.exp_factor) as str,
(offensive*o.exp_factor) as ofs,
(defensive*d.exp_factor) as dfs,
schedule_strength as sos
from ncaa._schedule_factors sf
left outer join ncaa.teams_divisions t
  on (t.team_id,t.year)=(sf.team_id,sf.year)
left outer join ncaa._factors o
  on (o.parameter,o.level)=('o_div',length(t.division)::text)
left outer join ncaa._factors d
  on (d.parameter,d.level)=('d_div',length(t.division)::text)
where sf.year in (2017)
and t.team_id is not null
order by str desc);

select
year,
exp(avg(log(str)))::numeric(5,3) as str,
exp(avg(log(ofs)))::numeric(5,3) as ofs,
exp(-avg(log(dfs)))::numeric(5,3) as dfs,
exp(avg(log(sos)))::numeric(5,3) as sos,
count(*) as n
from r
group by year
order by year asc;

select
year,
'D'||div as div,
exp(avg(log(str)))::numeric(5,3) as str,
exp(avg(log(ofs)))::numeric(5,3) as ofs,
exp(-avg(log(dfs)))::numeric(5,3) as dfs,
exp(avg(log(sos)))::numeric(5,3) as sos,
--avg(str)::numeric(5,3) as str,
--avg(ofs)::numeric(5,3) as ofs,
--(1/avg(dfs))::numeric(5,3) as dfs,
--avg(sos)::numeric(5,3) as sos,
count(*) as n
from r
where div is not null
group by year,div
order by year asc,str desc;

select * from r
where div is null
and year=2017;

commit;
