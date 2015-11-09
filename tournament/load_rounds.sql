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

-- matchup probabilities

drop table if exists ncaa.matrix_p;

create table ncaa.matrix_p (
	year				integer,
	field				text,
	team_id				integer,
	opponent_id			integer,
	team_p				float,
	opponent_p			float,
	primary key (year,field,team_id,opponent_id)
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,team_p,opponent_p)
(select
r1.year,
'home',
r1.team_id,
r2.team_id,
(h.strength*o.exp_factor)^2.0/
((h.strength*o.exp_factor)^2.0+(v.strength*d.exp_factor)^2.0)
  as home_p,
(v.strength*d.exp_factor)^2.0/
((v.strength*d.exp_factor)^2.0+(h.strength*o.exp_factor)^2.0)
  as visitor_p
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa._schedule_factors v
  on (v.year,v.team_id)=(r2.year,r2.team_id)
join ncaa._schedule_factors h
  on (h.year,h.team_id)=(r1.year,r1.team_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
where
  r1.year=2015
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,team_p,opponent_p)
(select
r1.year,
'away',
r1.team_id,
r2.team_id,
(h.strength*d.exp_factor)^2.0/
((h.strength*d.exp_factor)^2.0+(v.strength*o.exp_factor)^2.0)
  as home_p,
(v.strength*o.exp_factor)^2.0/
((v.strength*o.exp_factor)^2.0+(h.strength*d.exp_factor)^2.0)
  as visitor_p
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa._schedule_factors v
  on (v.year,v.team_id)=(r2.year,r2.team_id)
join ncaa._schedule_factors h
  on (h.year,h.team_id)=(r1.year,r1.team_id)
join ncaa._factors o
  on (o.parameter,o.level)=('field','offense_home')
join ncaa._factors d
  on (d.parameter,d.level)=('field','defense_home')
where
  r1.year=2015
);

insert into ncaa.matrix_p
(year,field,team_id,opponent_id,team_p,opponent_p)
(select
r1.year,
'neutral',
r1.team_id,
r2.team_id,
(h.strength)^2.0/
((h.strength)^2.0+(v.strength)^2.0)
  as home_p,
(v.strength)^2.0/
((v.strength)^2.0+(h.strength)^2.0)
  as visitor_p
from ncaa.rounds r1
join ncaa.rounds r2
  on ((r2.year)=(r1.year) and not((r2.team_id)=(r1.team_id)))
join ncaa._schedule_factors v
  on (v.year,v.team_id)=(r2.year,r2.team_id)
join ncaa._schedule_factors h
  on (h.year,h.team_id)=(r1.year,r1.team_id)
where
  r1.year=2015
);

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
  r1.year=2015
);

-- Massachusetts vs Kent St.

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id,opponent_id)=(2015,1,400,331);

update ncaa.matrix_field
set field='away'
where (year,round_id,team_id,opponent_id)=(2015,1,331,400);

-- Boston U. vs Fairfield

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id,opponent_id)=(2015,1,68,220);

update ncaa.matrix_field
set field='away'
where (year,round_id,team_id,opponent_id)=(2015,1,220,68);

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
where (year,round_id,team_id)=(2015,3,688);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,3,688);

-- Virginia

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2015,3,746);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,3,746);

-- UConn

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2015,3,164);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,3,164);

-- North Carolina

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2015,3,457);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,3,457);


-- 3rd and 4th round Michigan home

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2015,4,418);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,4,418);

update ncaa.matrix_field
set field='home'
where (year,round_id,team_id)=(2015,5,418);

update ncaa.matrix_field
set field='away'
where (year,round_id,opponent_id)=(2015,5,418);

commit;
