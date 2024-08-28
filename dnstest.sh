#!/usr/bin/env bash


command -v bc > /dev/null || { echo "error: bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "error: dig was not found. Please install dnsutils."; exit 1; }


NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

# 66.228.61.140#Archuser
# 149.112.121.20#CanadianShield
PROVIDERSV4="
210.220.163.82#SK-Broadband 
219.250.36.130#SK-Broadband2 
164.124.101.2#LGU+ 
203.248.252.2#LGU+2 
180.182.54.1#LG-Hellovision 
180.182.54.2#LG-Hellovision2 
94.140.14.14#Adguard 
94.140.14.140#Adguard-uf 
89.38.131.38#Alekberg
208.67.222.222#OpenDNS 
194.242.2.2#MullvadVPN 
185.222.222.222#dnssb 
1.1.1.1#Cloudflare 
1.0.0.1#Cloudflare2 
1.1.1.2#Cloudflare-am
1.0.0.2#Cloudflare-am2 
4.2.2.1#level3 
8.8.8.8#Google 
8.8.4.4#Google2 
9.9.9.9#Quad9 
199.85.126.20#norton 
185.228.168.168#cleanbrowsing 
156.154.70.3#neustar 
8.26.56.26#comodo
45.90.28.202#nextdns
"

PROVIDERSV6="
2a10:50c0::ad1:ff#adguard-v6
2a10:50c0::1:ff#adguarduf-v6
2a0c:b9c0:f:451d::1#alekberg-v6
2620:119:35::35#OpenDNS-v6
2a07:e340::2#mullvad-v6
2606:4700:4700::1111#cloudflare-v6
2001:4860:4860::8888#google-v6
2620:fe::fe#quad9-v6
2a0d:2a00:1::1#cleanbrowsing-v6
2a02:6b8::feed:0ff#yandex-v6
2610:a1:1018::3#neustar-v6
"

# Testing for IPv6
$dig +short +tries=1 +time=2 +stats @2a0d:2a00:1::1 www.google.com |grep 216.239.38.120 >/dev/null 2>&1
if [ $? = 0 ]; then
    hasipv6="true"
fi

providerstotest=$PROVIDERSV4

if [ "x$1" = "xipv6" ]; then
    if [ "x$hasipv6" = "x" ]; then
        echo "error: IPv6 support not found. Unable to do the ipv6 test."; exit 1;
    fi
    providerstotest=$PROVIDERSV6

elif [ "x$1" = "xipv4" ]; then
    providerstotest=$PROVIDERSV4

elif [ "x$1" = "xall" ]; then
    if [ "x$hasipv6" = "x" ]; then
        providerstotest=$PROVIDERSV4
    else
        providerstotest="$PROVIDERSV4 $PROVIDERSV6"
    fi
else
    providerstotest=$PROVIDERSV4
fi

    

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="namu.wiki cn.hongik.ac.kr www.naver.com www.google.com www.youtube.com www.letskorail.com wikipedia.org store.steampowered.com gmail.com"


totaldomains=0
printf "%-21s" ""
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
    printf "%-8s" "test$totaldomains"
done
printf "%-8s" "Average"
echo ""


for p in $NAMESERVERS $providerstotest; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0

    printf "%-21s" "$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
	        #let's have time out be 1s = 1000ms
	        ttime=1000
        elif [ "x$ttime" = "x0" ]; then
	        ttime=1
	    fi

        printf "%-8s" "$ttime ms"
        ftime=$((ftime + ttime))
    done
    avg=`bc -l <<< "scale=2; $ftime/$totaldomains"`

    echo "  $avg"
done


exit 0;
