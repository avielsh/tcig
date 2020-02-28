# tcig
Track cigarette smoking during the day
# Usage
```tcig [-f]``` - Add an entry for a smoke. ```-f``` = force

```tcig p [-f]``` - Add a partial smoke entry. ```-f``` = force

```tcig ls``` - List today's entries.

```tcig stats``` - Show total smoking stats.

```tcig dstats [date]``` - Show today's smoking stats.

```tcig rmlast``` - Remove latest entry.

```tcig replast``` - Replace latest entry from full to partial cigarette.

```tcig comp [date]``` - Compare smoking time to previous days. optional ```date``` can be a date or 3d for 3 days ago, 2w for 2 weeks ago etc. default is yesterday.

```tcig c``` - Check when last smoked

# Config

Edit the script to change database file and target pause between smoking a cigarette and partial cigarettes
```
cigfile="$HOME/cigs" #Change this path to your prefered cigfile
target=60 #target in minutes for next smoke
targetpartial=20 #target in minutes for next partial
```

# Aliases
Add these aliases to your .{bash,zsh}rc for quick entry

```
alias tc='tcig'
alias tcp='tcig p'
alias tcc='tcig c'
```
