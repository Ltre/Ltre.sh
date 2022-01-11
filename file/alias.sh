alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tailf='tail -f'
alias ll='ls -l --color=auto'

# du -sh * 的升级版，支持隐藏文件或目录，从大到小排列
alias dusha='dirs=`ls -a`; for one in $dirs; do if ! [[ "$one" =~ ^\.{1,2}$ ]];then du -sh $one; fi; done | sort -hr'
