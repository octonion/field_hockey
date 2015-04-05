#!/bin/bash

psql field_hockey -c "drop table if exists ncaa.results;"

psql field_hockey -f sos/standardized_results.sql

psql field_hockey -c "vacuum full verbose analyze ncaa.results;"

psql field_hockey -c "drop table ncaa._basic_factors;"
psql field_hockey -c "drop table ncaa._parameter_levels;"

R --vanilla -f sos/ncaa_lmer.R

psql field_hockey -c "vacuum full verbose analyze ncaa._parameter_levels;"
psql field_hockey -c "vacuum full verbose analyze ncaa._basic_factors;"

psql field_hockey -f sos/normalize_factors.sql
psql field_hockey -c "vacuum full verbose analyze ncaa._factors;"

psql field_hockey -f sos/schedule_factors.sql
psql field_hockey -c "vacuum full verbose analyze ncaa._schedule_factors;"

psql field_hockey -f sos/current_ranking.sql > sos/current_ranking.txt

psql field_hockey -f sos/division_ranking.sql > sos/division_ranking.txt

psql field_hockey -f sos/connectivity.sql > sos/connectivity.txt

psql field_hockey -f sos/test_predictions.sql > sos/test_predictions.txt

psql field_hockey -f sos/predict_daily.sql > sos/predict_daily.txt
cp /tmp/predict_daily.csv sos/predict_daily.csv

psql field_hockey -f sos/predict_spread.sql > sos/predict_spread.txt

psql field_hockey -f sos/predict_weekly.sql > sos/predict_weekly.txt
cp /tmp/predict_weekly.csv sos/predict_weekly.csv
