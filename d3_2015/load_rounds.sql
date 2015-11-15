begin;

-- rounds

drop table if exists ncaa.rounds;

create table ncaa.rounds (
	year				integer,
	round_id			integer,
	seed				integer,
	division_id			integer,
	team_id				integer,
	team_name			text,
	bracket				int[],
	p				float,
	primary key (year,round_id,team_id)
);

copy ncaa.rounds from '/tmp/rounds.csv' with delimiter as ',' csv header quote as '"';

drop table if exists ncaa.m;

create table ncaa.m (
       team_id				integer,
       c				float,
       tof				float,
       tdf				float,
       ofd				float,
       dfd				float,
       primary key (team_id)
);

insert into ncaa.m
(team_id,c,tof,tdf,ofd,dfd)
(select
r.team_id as team_id,
exp(i.estimate)*y.exp_factor as c,
hdof.exp_factor*h.offensive as tof,
h.defensive*hddf.exp_factor as tdf,
o.exp_factor as ofd,
d.exp_factor as dfd
from ncaa.rounds r
join ncaa._schedule_factors h
  on (h.year,h.team_id)=(r.year,r.team_id)
join ncaa.teams_divisions hd
  on (hd.year,hd.team_id)=(r.year,r.team_id)
join ncaa._factors hdof
  on (hdof.parameter,hdof.level::integer)=('o_div',hd.div_id)
join ncaa._factors hddf
  on (hddf.parameter,hddf.level::integer)=('d_div',hd.div_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
join ncaa._factors y
  on (y.parameter,y.level)=('year',r.year::text)
join ncaa._basic_factors i
  on (i.factor)=('(Intercept)')

);

-- matchup probabilities

drop table if exists ncaa.matrix_p;

create table ncaa.matrix_p (
	year				integer,
	field				text,
	team_id				integer,
	opponent_id			integer,
	t_mu				float,
	to_mu				float,
	team_p				float,
	o_mu				float,
	oo_mu				float,
	opponent_p			float,
	primary key (year,field,team_id,opponent_id)
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'home',
r1.team_id,
r2.team_id,
(m1.c*m1.tof*m1.ofd*m2.tdf) as t_mu,
(15.0/70.0)*(m1.c*m1.tof*m1.ofd*m2.tdf) as to_mu,
(m1.c*m2.tof*m2.dfd*m1.tdf) as o_mu,
(15.0/70.0)*(m1.c*m2.tof*m2.dfd*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa.m m1
  on (m1.team_id)=(r1.team_id)
join ncaa.m m2
  on (m2.team_id)=(r2.team_id)
where
  r1.year=2016
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'away',
r1.team_id,
r2.team_id,
(m1.c*m1.tof*m1.dfd*m2.tdf) as t_mu,
(15.0/70.0)*(m1.c*m1.tof*m1.dfd*m2.tdf) as to_mu,
(m1.c*m2.tof*m2.ofd*m1.tdf) as o_mu,
(15.0/70.0)*(m1.c*m2.tof*m2.ofd*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa.m m1
  on (m1.team_id)=(r1.team_id)
join ncaa.m m2
  on (m2.team_id)=(r2.team_id)
where
  r1.year=2016
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,t_mu,to_mu,o_mu,oo_mu)
(select
r1.year,
'neutral',
r1.team_id,
r2.team_id,
(m1.c*m1.tof*m2.tdf) as t_mu,
(15.0/70.0)*(m1.c*m1.tof*m2.tdf) as to_mu,
(m1.c*m2.tof*m1.tdf) as o_mu,
(15.0/70.0)*(m1.c*m2.tof*m1.tdf) as oo_mu
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa.m m1
  on (m1.team_id)=(r1.team_id)
join ncaa.m m2
  on (m2.team_id)=(r2.team_id)
where
  r1.year=2016
);

update ncaa.matrix_p
set
team_p=
(skellam(t_mu,o_mu,'win')
+skellam(t_mu,o_mu,'draw')*to_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+skellam(t_mu,o_mu,'draw')*exp(-to_mu-oo_mu)*to_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+0.5*skellam(t_mu,o_mu,'draw')*exp(-2*to_mu)*exp(-2*oo_mu)),

opponent_p=
(skellam(t_mu,o_mu,'lose')
+skellam(t_mu,o_mu,'draw')*oo_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+skellam(t_mu,o_mu,'draw')*exp(-to_mu-oo_mu)*oo_mu/(to_mu+oo_mu)*(1-exp(-to_mu-oo_mu))
+0.5*skellam(t_mu,o_mu,'draw')*exp(-2*to_mu)*exp(-2*oo_mu));

-- home advantage

-- Determined by:

drop table if exists ncaa.matrix_field;

create table ncaa.matrix_field (
	year				integer,
	round_id			integer,
	team_id				integer,
	opponent_id			integer,
	field				text,
	primary key (year,round_id,team_id,opponent_id)
);

insert into ncaa.matrix_field
(year,round_id,team_id,opponent_id,field)
(select
r1.year,
gs.round_id,
r1.team_id,
r2.team_id,
'neutral'
from ncaa.rounds r1
join ncaa.rounds r2
  on (r2.year=r1.year and not(r2.team_id=r1.team_id))
join (select generate_series(1, 5) round_id) gs
  on TRUE
where
  r1.year=2016
);

-- Massachusetts vs Kent St.

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id,opponent_id)=(2016,1,400,331);

update ncaa.matrix_field
set field='away'
where (year,round_id,team_id,opponent_id)=(2016,1,331,400);

-- Boston U. vs Fairfield

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id,opponent_id)=(2016,1,68,220);

update ncaa.matrix_field
set field='away'
where (year,round_id,team_id,opponent_id)=(2016,1,220,68);

-- 1st and 2nd round seeds have home

update ncaa.matrix_field
set field='home'
from ncaa.rounds r
where (r.year,r.team_id)=
      (matrix_field.year,matrix_field.team_id)
and r.round_id=1
and matrix_field.round_id=2
and r.seed is not null;

update ncaa.matrix_field
set field='away'
from ncaa.rounds r
where (r.year,r.team_id)=
      (matrix_field.year,matrix_field.team_id)
and r.round_id=1
and matrix_field.round_id=2
and r.seed is null;

-- 2nd round

-- Syracuse

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,3,688);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,3,688);

-- Virginia

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,3,746);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,3,746);

-- UConn

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,3,164);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,3,164);

-- North Carolina

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,3,457);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,3,457);


-- 3rd and 4th round Michigan home

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,4,418);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,4,418);

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2016,5,418);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2016,5,418);

commit;
