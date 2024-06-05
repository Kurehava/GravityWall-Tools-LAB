n=$((100/10))
N=$((100/20))
for i in `seq 500`
do 
    sleep 0.01
    [ $(($i%$n)) -eq 0 ] && echo -ne "\b=" && continue
    [ $(($i%$N)) -eq 0 ] && echo -ne "-"
done
echo ""