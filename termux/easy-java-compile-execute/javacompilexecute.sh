# Requirements: pkg i ecj dx
# Usage: ~/bin/javacompilexecute CLASS_NAME

rm -f "${1}.class" "${1}.dex"
ecj "${1}.java"
dx --dex --output="${1}.dex"  "${1}.class"
dalvikvm -cp "${1}.dex" "${1}" # execute your program
