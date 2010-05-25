#!/bin/sh
export PERL5LIB=blib/lib
rm -f /tmp/smeagol_datastore/*
# compte! els accents no funcionen be encara
perl ./client.pl --c=createResource --des="D6-S103" --gra="sala comu" --info="biblioteca del DAC"
# reserva 1
perl ./client.pl --c=createBooking --id=1 --des="reunio setmanal de la cpl" --from=2009/04/02_09:30:00 --to=2009/04/02_14:00:00
# reserva 2
perl ./client.pl --c=createBooking --id=1 --des="activitat extra" --from=2009/04/02_15:00:00 --to=2009/04/02_18:00:00
