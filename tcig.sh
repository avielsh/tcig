#!/bin/zsh
cigfile="$HOME/cigs"
now=$(gdate +'%m-%d %H:%M')
today=$(echo $now | awk '{print $1}')
msg_partial="Smooked partial"
msg_one="Smooked one"
OLDIFS="$IFS"

date_diff() {
  old=$1
  new=$2
  OLDIFS="$IFS"
  IFS=:
  echo "$old" | read old_hour old_min
  echo "$new" | read hour min
  IFS="$OLDIFS"
# convert the date "1970-01-01 hour:min:00" in seconds from Unix EPOCH time
  sec_old=$(gdate -d "1970-01-01 $old_hour:$old_min:00" +%s)
  sec_new=$(gdate -d "1970-01-01 $hour:$min:00" +%s)
  echo "$(( (sec_new - sec_old) / 60))"
}

last_cig_difference() {
  last=$(tail -1 $cigfile | awk '{print $2}')
  thiscig=$(echo $now | awk '{print $2}')
  diff=$(date_diff $last $thiscig)
  echo Last ciggarette was $diff minutes ago
}

addcig() {
  last_cig_difference
  echo $now $msg_one >> $cigfile
}

addpartialcig() {
  last_cig_difference
  echo $now $msg_partial >> $cigfile
}

getstats() {
 # rev $cigfile | uniq -c -f 2 | rev
 total=$(awk '{print $1}' $cigfile | uniq -c)
 partial=$(grep $msg_partial $cigfile | awk '{print $1}' | uniq -c)
 one=$(grep $msg_one $cigfile | awk '{print $1}' | uniq -c)
 echo Total 
 echo "$total"  
 echo Partial
 echo "$partial"
 echo One
 echo "$one"
}

gettodaystats() {
  local alldiffs=()
  partial=$(grep $msg_partial $cigfile | grep $today | awk '{print $1}' | uniq -c | awk '{print $1}')
  one=$(grep $msg_one $cigfile | grep $today | awk '{print $1}' | uniq -c | awk '{print $1}')
  alltimes=$(cat $cigfile | grep $today | awk '{print $2}')

  echo "$alltimes" | while read time
  do
    [[ -z $prevtime ]] && prevtime=$time && continue
    diff=$(date_diff $prevtime $time)
    alldiffs+=$diff
    prevtime=$time
  done
  IFS=$'\n'
  maxdiff=$(echo "$alldiffs[*]" | sort -nr | head -n1)
  mindiff=$(echo "$alldiffs[*]" | sort -nr | tail -1)
  IFS="$OLDIFS"
  echo "One: $one"
  echo "Partial: $partial"
  echo "Time differences between smokes: $alldiffs"
  echo "Longest duration between smokes: $maxdiff"
  echo "Shortest duration between smokes: $mindiff"
}

[[ -z $1 ]] && addcig
[[ $1 == "p" ]] && addpartialcig
[[ $1 == "tstats" ]] && gettodaystats
[[ $1 == "stats" ]] && getstats
[[ $1 == "rmlast" ]] && gsed -i '$d' $cigfile
[[ $1 == "ls" ]] && grep $today $cigfile
