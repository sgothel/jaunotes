cd /home

rm -rf shg/sieve  shg/.dovecot.s*
cp -a catchall/sieve  catchall/.dovecot.s* shg/
chown -R shg:shg shg/.dovecot.s* shg/sieve

rm -rf shg-gyo/sieve  shg-gyo/.dovecot.s*
cp -a catchall/sieve  catchall/.dovecot.s* shg-gyo/
chown -R shg-gyo:shg-gyo shg-gyo/.dovecot.s* shg-gyo/sieve

rm -rf hkg/sieve  hkg/.dovecot.s*
cp -a catchall/sieve  catchall/.dovecot.s* hkg
chown -R hkg:hkg hkg/.dovecot.s* hkg/sieve

rm -rf hkg-pub/sieve  hkg-pub/.dovecot.s*
cp -a catchall/sieve  catchall/.dovecot.s* hkg-pub/
chown -R hkg-pub:hkg-pub hkg-pub/.dovecot.s* hkg-pub/sieve
