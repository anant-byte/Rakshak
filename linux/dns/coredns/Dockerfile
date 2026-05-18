FROM coredns/coredns:1.11.1
# RAKSHAK uses stock CoreDNS with hosts, cache, forward, health, prometheus plugins
COPY Corefile /etc/coredns/Corefile
EXPOSE 53/udp 53/tcp 8081 9153
