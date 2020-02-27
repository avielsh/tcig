#!/bin/zsh
cigfile="$HOME/cigs" #Change this path to your prefered cigfile
target=60 #target in minutes for next smoke
targetpartial=20 #target in minutes for next partial
now=$(gdate +'%m-%d %H:%M')
today=$(echo $now | awk '{print $1}')

msg_partial="Smoked partial"
msg_one="Smoked one"

OLDIFS="$IFS"

red=$(tput setaf 1)
blue=$(tput setaf 4)
white=$(tput setaf 7)
green=$(tput setaf 10)
yellow=$(tput setaf 3)
purple=$(tput setaf 13)

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

get_cig_diff() {
  local last thiscig diff 
  tail -1 $cigfile | grep -q $today || { echo "No cigarettes smoked today (yet)" ; return ; }
  last=$(tail -1 $cigfile | helper_get_time)
  thiscig=$(echo $now | helper_get_time)
  diff=$(date_diff $last $thiscig)
  echo $diff
}

last_cig_difference() {
  local diff
  diff=$(get_cig_diff)
  echo Last cigarette was $(get_hours $diff) ago
}

addcig() {
  local diff
  last_cig_difference 
  diff=$(get_cig_diff)
  (( $diff < $target )) && echo "${red}Error${white} - Will not add entry since you have not reached your target pause time between cigarettes! ($(get_hours $target))" ||
    echo $now $msg_one >> $cigfile
}

addpartialcig() {
  local diff
  last_cig_difference 
  diff=$(get_cig_diff)
  (( $diff < $targetpartial )) && echo "${red}Error${white} - Will not add entry since you have not reached your target pause time between partial cigarettes! ($(get_hours $targetpartial))" ||
    echo $now $msg_partial >> $cigfile
}

helper_get_date() {
  while read -r line
  do
    echo $line | awk '{print $1}'
  done
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
      [[ $timeago =~ ^[0-9]{2}-[0-9]{2}$ ]] && timeago="$(gdate +'%Y')-${timeago}"
      #handle reversed day-month
      gdate -d $timeago 2>/dev/null || { IFS=- read year month day <<<"$timeago"
        timeago=$year-$day-$month ; }
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

case $1 in
  c)
    last_cig_difference
    ;;
  p)
    addpartialcig
    ;;
  tstats)
    gettodaystats
    ;;
  stats)
    getstats
    ;;
  rmlast)
    gsed -i '$d' $cigfile
    ;;
  replast)
    gsed -i '$'"s/$msg_one/$msg_partial/" $cigfile
    ;;
  comp)
    compare_days $2
    ;;
  ls)
    grep $today $cigfile
    ;;
esac
[[ -z $1 ]] && addcig
