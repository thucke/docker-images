# Oracle Database XE on Docker
Sample Docker build files to facilitate installation, configuration, and environment setup for DevOps users. For more information about Oracle Database please see the [Oracle XE Database Online Documentation](http://www.oracle.com/technetwork/database/database-technologies/express-edition/documentation/index.html).

## How to build and run
This project offers a sample Dockerfile for Oracle Database 11g Release 2 (11.2.0.2) Express Edition.

To assist in building the images, you can use the [buildDockerImage.sh](dockerfiles/buildDockerImage.sh) script. See below for instructions and usage.

The `buildDockerImage.sh` script is just a utility shell script that performs MD5 checks and is an easy way for beginners to get started. Expert users are welcome to directly call `docker build` with their prefered set of parameters.

### Building Oracle Database Docker Install Images
**IMPORTANT:** You will have to provide the installation binaries of Oracle Database and put them into the `dockerfiles/<version>` folder. You only need to provide the binaries for the edition you are going to install. The binaries can be downloaded from the [Oracle Database Express Edition Downloads](http://www.oracle.com/technetwork/database/database-technologies/express-edition/downloads/index.html) page. You also have to make sure to have internet connectivity for yum. Note that you must not uncompress the binaries. The script will handle that for you and fail if you uncompress them manually!

Before you build the image make sure that you have provided the installation binaries and put them into the right folder. Once you have done this, go into the **dockerfiles** folder and run the **buildDockerImage.sh** script as root or with `sudo` privileges:

    [oracle@localhost dockerfiles]$ ./buildDockerImage.sh -h
    
    Usage: buildDockerImage.sh [-i] [-o] [Docker build option]
    Builds a Docker Image for Oracle Database.
    
    Parameters:
       -i: ignores the MD5 checksums
       -o: passes on Docker build option
    
    

**IMPORTANT:** The resulting images will be an image with the Oracle binaries installed. On first startup of the container a new database will be created, the following lines highlight when the database is ready to be used:

	#########################
	DATABASE IS READY TO USE!
	#########################

You may extend the image with your own Dockerfile and create the users and tablespaces that you may need.

The character set for the database is set during creating of the database. 11g Express Edition supports only UTF-8.


#### Running Oracle Database Express Edition in a Docker container
To run your Oracle Database Express Edition Docker image use the **docker run** command as follows:

	docker run --name <container name> \
	--shm-size=1g \
	-p 1521:1521 -p 8080:8080 -p 33669:33669 \
	-e ORACLE_PWD=<your database passwords> \
	-v [<host mount point>:]/u01/app/oracle/oradata \
	thucke/oraclexe:11.2.0.2
	
	Parameters:
	   --name:        The name of the container (default: auto generated)
	   --shm-size:    Amount of Linux shared memory
	   -p:            The port mapping of the host port to the container port.
	                  Three ports are exposed: 1521 (Oracle Listener), 8080 (APEX), 33669 (Shared server)
	   -e ORACLE_PWD: The Oracle Database SYS, SYSTEM and PDB_ADMIN password (default: auto generated)

	   -v /u01/app/oracle/oradata
	                  The data volume to use for the database.
	                  Has to be writable by the Unix "oracle" (uid: 54321) user inside the container!
	                  If omitted the database will not be persisted over container recreation.
	   -v /u01/app/oracle/scripts/startup | /docker-entrypoint-initdb.d
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.
	   -v /u01/app/oracle/scripts/setup | /docker-entrypoint-initdb.d
	                  Optional: A volume with custom scripts to be run after database startup.
	                  For further details see the "Running scripts after setup and on startup" section below.

There are three ports that are exposed in this image:
* 1521 which is the port to connect to the Oracle Database.
* 8080 which is the port of Oracle Application Express (APEX).
* 33669 which is the port to connect the running shared server dispatcher

On the first startup of the container a random password will be generated for the database if not provided. You can find this password in the output line:

	ORACLE PASSWORD FOR SYS AND SYSTEM:

The password for those accounts can be changed via the **docker exec** command. **Note**, the container has to be running:
	docker exec <container name> /u01/app/oracle/setPassword.sh <your password>

Once the container has been started you can connect to it just like to any other database:

	sqlplus sys/<your password>@XE as sysdba
	sqlplus system/<your password>@XE

### Application Express (APEX) ###

The Oracle Database inside the container also has Oracle Application Express configured. To access APEX, start your browser and follow the URL:

	http://localhost:8080/apex/apex_admin

If you lack the ability to login using a password you could set an new password into the preinstalles APEX installation. After the following command has been executed you're able to login using credentials admin/admin.

```bash
docker exec -ti <container name> su -p oracle -c "sqlplus / as sysdba @$ORACLE_HOME/apex/apxxepwd.sql admin"
```

You might to install the latest version of APEX just when creating the container. For that please download the appropiate file from the [Oracle Application Express Downloads](http://www.oracle.com/technetwork/developer-tools/apex/downloads/index.html) page and put that file into the later described setup folder. ... together with the provided file [install_apex.sh](setup/install_apex.sh).
Open up this file and adjust the pre-configured filename that it fits the name of the downloadefile.

**ATTENTION**
The setup process wll last much longer than without the upgrade. Finally you are asked entering new credentials for the APEX admin account. If no question appears you may log into sqlplus to execute the passwort reset script:

```bash
docker exec -ti <container name> su -p oracle -c "sqlplus / as sysdba @/u01/app/oracle/oradata/dbconfig/XE/apxchpwd.sql"
```


### Running scripts after setup and on startup
The docker images can be configured to run scripts after setup and on startup. Currently `sh` and `sql` extensions are supported.
For post-setup scripts just mount the volume `/u01/app/oracle/scripts/setup` or extend the image to include scripts in this directory.
For post-startup scripts just mount the volume `/u01/app/oracle/scripts/startup` or extend the image to include scripts in this directory.
Both of those locations are also represented under the symbolic link `/docker-entrypoint-initdb.d`. This is done to provide
synergy with other database Docker images. The user is free to decide whether he wants to put his setup and startup scripts
under `/u01/app/oracle/scripts` or `/docker-entrypoint-initdb.d`.

After the database is setup and/or started the scripts in those folders will be executed against the database in the container.
SQL scripts will be executed as sysdba, shell scripts will be executed as the current user. To ensure proper order it is
recommended to prefix your scripts with a number. For example `01_users.sql`, `02_permissions.sql`, etc.

**Note:** The startup scripts will also be executed after the first time database setup is complete.

The example below mounts the local directory myScripts to `/opt/oracle/myScripts` which is then searched for custom startup scripts:

```bash
docker run --name <container name> -p 1521:1521  -p 8080:8080 -p 33669:33669 -v /home/oracle/myScripts:/u01/app/oracle/scripts/startup -v /home/oracle/oradata:/opt/oracle/oradata thucke/oraclexe:11.2.0.2
```
    
## Further information
Please see [Oracle Database on Docker Github page](https://github.com/oracle/docker-images/tree/master/OracleDatabase) for further information.

You may also make use of the [Oracle SQL Developer](http://www.oracle.com/technetwork/developer-tools/sql-developer/overview/index.html) to access your newly installed database.

## License
To download and run Oracle Database, regardless whether inside or outside a Docker container, you must download the binaries from the Oracle website and accept the license indicated at that page.

All scripts and files hosted in this project and GitHub [docker-images/OracleDatabase](./) repository required to build the Docker images are, unless otherwise noted, released under [UPL 1.0](https://oss.oracle.com/licenses/upl/) license.

## Copyright
Copyright (c) 2014-2017 Oracle and/or its affiliates. All rights reserved.
