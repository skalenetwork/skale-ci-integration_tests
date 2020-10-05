set term png small size 800,600
set output "skaled_chart.png"
#set term wxt size 800,600

set datafile separator " "

set xdata time
set timefmt "%s"

set ylabel "blocks"
set y2label "txns"

set ytics nomirror
set y2tics nomirror in

set yrange [0:*]
set y2range [0:*]

plot "skaled_chart.txt" using 1:2 with lines axes x1y1 title "blocks", \
     "skaled_chart.txt" using 1:3 with lines axes x1y2 title "txns"
