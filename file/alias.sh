alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias tailf='tail -f'
alias ll='ls -l --color=auto'

# du -sh * 的升级版，支持隐藏文件或目录，从大到小排列
alias dusha='dirs=`ls -a $1`; for one in $dirs; do if ! [[ "$one" =~ ^\.{1,2}$ ]];then du -sh $one; fi; done | sort -hr'


# @todo [[ "$1" =~ \* ]] 不能拦截参数1使用星号的情况，因为shell执行前会把星号解释称具体的文件或目录名
dusha() {
    if [[ "$1" =~ \* ]] || (! [ -d "$1" ] && ! [[ "$1" =~ ^$ ]]); then
        echo 'warning: arg 1 must be an exact folder or empty string.'
        return
    fi
    dirs=`ls -a $1`
    prefpath=`if [ ${#1} -eq 0 ]; then echo; else echo $1/; fi`
    for one in $dirs
    do
        if ! [[ "$one" =~ ^\.{1,2}$ ]]; then
            du -sh ${prefpath}${one};
        fi
    done | sort -hr
}
