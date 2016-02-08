#!/bin/bash

whoami >> /tmp/asm_diskgroup.log

export PATH=/usr/local/bin:$PATH
export ORACLE_SID=+ASM
export ORAENV_ASK=NO
. oraenv > /tmp/asm_diskgroup.log 2>&1

$ORACLE_HOME/bin/asmca -silent -createDiskGroup -diskGroupName DATA -diskList $DISKLIST "/dev/oracleasm/disk1,/dev/oracleasm/disk2,/dev/oracleasm/disk3" -redundancy EXTERNAL -au_size 1 >> /tmp/asm_diskgroup.log
$ORACLE_HOME/bin/asmca -silent -createDiskGroup -diskGroupName RECO -diskList $DISKLIST "/dev/oracleasm/disk4,/dev/oracleasm/disk5" -redundancy EXTERNAL -au_size 1 >> /tmp/asm_diskgroup.log

exit 0
