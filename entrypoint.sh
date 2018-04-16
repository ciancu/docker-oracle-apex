#!/bin/bash

unzip /tmp/instantclient-basic-linux.x64-12.1.0.2.0.zip -d /
unzip /tmp/instantclient-sqlplus-linux.x64-12.1.0.2.0.zip -d /

SQLPLUS=/instantclient_12_1/sqlplus
SQLPLUS_ARGS="${USER}/${PASS}@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=${HOST})(Port=${PORT}))(CONNECT_DATA=(SID=${SID}))) as sysdba"

verify(){
	echo "exit" | ${SQLPLUS} -L $SQLPLUS_ARGS | grep Connected > /dev/null
	if [ $? -eq 0 ];
	then
	   echo "Database Connetion is OK"
	else
	   echo -e "Database Connection Failed. Connection failed with:\n $SQLPLUS -S $SQLPLUS_ARGS\n `$SQLPLUS -S $SQLPLUS_ARGS` < /dev/null"
	   echo -e "run example:\n docker run -it --rm --volumes-from $oracle_db_name:oracle-database --link $oracle_db_name:oracle-database sath89/apex install"
	   exit 1
	fi

	if [ "$(ls -A /u01/app/oracle)" ]; then
		echo "Check Database files folder: OK"
	else
		echo -e "Failed to find database files, run example:\n docker run -it --rm --volumes-from $oracle_db_name:oracle-database --link $oracle_db_name:oracle-database sath89/apex install"
		exit 1
	fi
}

disable_http(){
	echo "Turning off DBMS_XDB HTTP port"
	echo "EXEC DBMS_XDB.SETHTTPPORT(0);" | $SQLPLUS -S $SQLPLUS_ARGS
}

enable_http(){
	echo "Turning on DBMS_XDB HTTP port"
	echo "EXEC DBMS_XDB.SETHTTPPORT($HTTP_PORT);" | $SQLPLUS -S $SQLPLUS_ARGS
}

get_oracle_home(){
	echo "Getting ORACLE_HOME Path"
	ORACLE_HOME=`echo -e "var ORACLEHOME varchar2(200);\n EXEC dbms_system.get_env('ORACLE_HOME', :ORACLEHOME);\n PRINT ORACLEHOME;" | $SQLPLUS -S $SQLPLUS_ARGS | grep "/.*/"`
	echo "ORACLE_HOME found: $ORACLE_HOME"
}

apex_upgrade(){
	cd /tmp/apex_patch_${APEX_PATCH}/patch/
	echo "Upgrading apex..."
	$SQLPLUS -S $SQLPLUS_ARGS @apxpatch.sql < /dev/null
	echo "Updating apex images"
	$SQLPLUS -S $SQLPLUS_ARGS @apxldimg.sql /tmp/apex_patch_${APEX_PATCH}/patch < /dev/null
}

unzip_apex(){
	echo "Extracting Apex patch-${APEX_PATCH}"
	unzip /apex_patch/p${APEX_PATCH}_Generic.zip -d /tmp/apex_patch_${APEX_PATCH}/
}


case $1 in
	'install')
		verify
		unzip_apex
		disable_http
		apex_upgrade
		enable_http
		;;
	*)
		$1
		;;
esac