#!/bin/zsh
cigfile="$HOME/cigs"
now=$(gdate +'%m-%d %H:%M')
yesterday=$(gdate -d "-1days" +'%m-%d %H:%M')
today=$(echo $now | awk '{print $1}')
msg_partial="Smoked partial"
msg_one="Smoked one"
OLDIFS="$IFS"

date_diff() {
  local old new sec_old sec_new
  old=$1
  new=$2
  IFS=":" read old_hour old_min <<< "$old"
  IFS=":" read hour min <<< "$new"
# convert the date "1970-01-01 hour:min:00" in seconds from Unix EPOCH time
  sec_old=$(gdate -d "1970-01-01 $old_hour:$old_min:00" +%s)
  sec_new=$(gdate -d "1970-01-01 $hour:$min:00" +%s)
  echo "$(( (sec_new - sec_old) / 60))"
}

last_cig_difference() {
  local last thiscig diff
  tail -1 $cigfile | grep -q $today || { echo "No cigarettes smoked today (yet)" ; return ; }
  last=$(tail -1 $cigfile | helper_get_time)
  thiscig=$(echo $now | helper_get_time)
  diff=$(date_diff $last $thiscig)
  echo Last cigarette was $diff minutes ago
}

addcig() {
  last_cig_difference
  echo $now $msg_one >> $cigfile
}

addpartialcig() {
  last_cig_difference
  echo $now $msg_partial >> $cigfile
}

helper_get_date() {
  read -r line
  echo $line | awk '{print $1}'
}


helper_get_time() {
  while read -r line
  do
    echo $line | awk '{print $2}'
  done
}

getstats() {
  local total partial one
  # rev $cigfile | uniq -c -f 2 | rev
  total=$(awk '{print $1}' $cigfile | uniq -c)
  partial=$(grep $msg_partial $cigfile | helper_get_date | uniq -c)
  one=$(grep $msg_one $cigfile | helper_get_date | uniq -c)
  echo Total 
  echo "$total"  
  echo Partial
  echo "$partial"
  echo One
  echo "$one"
}

compare_with_day() {
  case $1 in 
    *d)
      timeago="-${1}ays"
      ;;
    w)
      timeago="-7days"
      ;;
    *)
      timeago=$1
      ;;
  esac
  [[ -z $1 ]] && timeago="-1days"
  theday=$(gdate -d "$timeago" +'%m-%d %H:%M')
  thedaydate=$(echo $theday | helper_get_date)

  daytimes=$(cat $cigfile | grep $thedaydate | helper_get_time)
  (( $(echo $daytimes | wc -l) <= 1 )) && echo No data for $thedaydate && return
  todaytimes=$(cat $cigfile | grep $today | helper_get_time)
  echo "Smoking times compared to $thedaydate\n"
  paste <(echo $daytimes) <(echo $todaytimes)
}

compare_days() {
  compare_with_day $*
}

get_hours() {
  minutes=$1
  (( $minutes > 60 )) && echo "$(( $minutes /60 )) hours, $(( $minutes % 60 )) minutes" && return
  echo "$minutes minutes"
}

gettodaystats() {
  local partial one alltimes diff alldiffs prevtime maxdiff mindiff
  declare -a alldiffs
  partial=$(grep $msg_partial $cigfile | grep $today | helper_get_date | uniq -c | awk '{print $1}')
  one=$(grep $msg_one $cigfile | grep $today | helper_get_date | uniq -c | awk '{print $1}')
  alltimes=$(cat $cigfile | grep $today | helper_get_time)

  echo "$alltimes" | while read time
  do
    [[ -z $prevtime ]] && prevtime=$time && continue
    diff=$(date_diff $prevtime $time)
    alldiffs+=$diff
    prevtime=$time
  done
  IFS=$'\n'
  maxdiff=$(get_hours $(echo "$alldiffs[*]" | sort -nr | head -n1))
  mindiff=$(get_hours $(echo "$alldiffs[*]" | sort -nr | tail -1) )
  average=$(get_hours $(( $( echo "$alldiffs[*]"| paste -sd+ - | bc ) / ${#alldiffs[@]} )) )
  IFS="$OLDIFS"
  printf '%-35s %s\n'  "One:" "$one cigarettes"
  printf '%-35s %s\n'  "Partial:" "$partial cigarettes"
  printf '%-35s %s\n' "Time differences between smokes:" "$alldiffs"
  printf '%-35s %s\n' "Longest duration between smokes:" "$maxdiff"
  printf '%-35s %s\n' "Shortest duration between smokes:" "$mindiff"
  printf '%-35s %s\n' "Average duration between smokes:" "$average"
}

[[ -z $1 ]] && addcig
[[ $1 == "c" ]] && last_cig_difference
[[ $1 == "p" ]] && addpartialcig
[[ $1 == "tstats" ]] && gettodaystats
[[ $1 == "stats" ]] && getstats
[[ $1 == "rmlast" ]] && gsed -i '$d' $cigfile
[[ $1 == "replast" ]] && gsed -i '$'"s/$msg_one/$msg_partial/" $cigfile
[[ $1 == "comp" ]] && compare_days $2
[[ $1 == "ls" ]] && grep $today $cigfile

