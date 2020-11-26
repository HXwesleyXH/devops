#!/bin/sh

# Senha Root do MySQL
dbroot="root@zabbix_2020"

# Senha de usuário do Zabbix
dbzabbix="root@zabbix_2020"

# Senha do usuário de monitoramento do MySQL
monzabbix="root@zabbix_2020"

# URL do Zabbix Server
zabbixurl="https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.4.tar.gz"

# Váriavel para nome da URL zabbix Server
zabbixarchive=$(basename "$zabbixurl")

# Onde a fonte do Zabbix estará
srcdir="/usr/local/src"

# Timezone do PHP
phptz="America/Sao_Paulo"

# Configuração do Zabbix Server
zabbixconf="/usr/local/etc/zabbix_server.conf"

# Arquitetura
arch=$(uname -m)

# Diretório temporário
tmpdir="$HOME/temp"

# stdout e stderr 
logfile="$PWD/install.log"
rm -f $logfile

# Log Simples# Log Simples
log(){
	timestamp=$(date +"%m-%d-%Y %k:%M:%S")
	echo "$timestamp $1"
	echo "$timestamp $1" >> $logfile 2>&1
}

log "Removendo diretório temporário $tmpdir"
rm -rf "$tmpdir" >> $logfile 2>&1
mkdir -p "$tmpdir" >> $logfile 2>&1

log "Instalando o MySQL..."
sudo -E apt-get -y update >> $logfile 2>&1
sudo -E apt-get -y install mysql-server mysql-client >> $logfile 2>&1
# MySQL seguro, criação do BD Zabbix e criação de usuários no Zabbix.
sudo -E mysql --user=root <<_EOF_
ALTER USER 'root'@'localhost' IDENTIFIED BY '${dbroot}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE zabbix CHARACTER SET UTF8 COLLATE UTF8_BIN;
CREATE USER 'zabbix'@'%' IDENTIFIED BY '${dbzabbix}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'%';
CREATE USER 'zbx_monitor'@'%' IDENTIFIED BY '${monzabbix}';
GRANT USAGE,REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'%';
FLUSH PRIVILEGES;
_EOF_

# Estrutura JDK
javahome=/usr/lib/jvm/jdk11
export javahome
# ARM 32
if [ "$arch" = "armv7l" ]; then
	jdkurl="https://cdn.azul.com/zulu-embedded/bin/zulu11.41.75-ca-jdk11.0.8-linux_aarch32hf.tar.gz"
# ARM 64
elif [ "$arch" = "aarch64" ]; then
	jdkurl="https://cdn.azul.com/zulu-embedded/bin/zulu11.41.75-ca-jdk11.0.8-linux_aarch64.tar.gz"
# X86_32
elif [ "$arch" = "i586" ] || [ "$arch" = "i686" ]; then
	jdkurl="https://cdn.azul.com/zulu/bin/zulu11.41.23-ca-jdk11.0.8-linux_i686.tar.gz"
# X86_64	
elif [ "$arch" = "x86_64" ]; then
    jdkurl="https://cdn.azul.com/zulu/bin/zulu11.41.23-ca-jdk11.0.8-linux_x64.tar.gz"
fi
# Váriavel para nome da URL JDK
jdkarchive=$(basename "$jdkurl")

# Instala Zulu Java JDK
log "Baixando $jdkarchive em $tmpdir"
wget -q --directory-prefix=$tmpdir "$jdkurl" >> $logfile 2>&1
log "Extraindo $jdkarchive para $tmpdir"
tar -xf "$tmpdir/$jdkarchive" -C "$tmpdir" >> $logfile 2>&1
log "Removendo $javahome"
sudo -E rm -rf "$javahome" >> $logfile 2>&1
# Remove .gz
filename="${jdkarchive%.*}"
# Remove .tar
filename="${filename%.*}"
sudo mkdir -p /usr/lib/jvm >> $logfile 2>&1
log "Movendo $tmpdir/$filename to $javahome"
sudo -E mv "$tmpdir/$filename" "$javahome" >> $logfile 2>&1
sudo -E update-alternatives --install "/usr/bin/java" "java" "$javahome/bin/java" 1 >> $logfile 2>&1
sudo -E update-alternatives --install "/usr/bin/javac" "javac" "$javahome/bin/javac" 1 >> $logfile 2>&1
sudo -E update-alternatives --install "/usr/bin/jar" "jar" "$javahome/bin/jar" 1 >> $logfile 2>&1
sudo -E update-alternatives --install "/usr/bin/javadoc" "javadoc" "$javahome/bin/javadoc" 1 >> $logfile 2>&1
# Verifica se JAVA_HOME existe e se não, adiciona /etc/environment
if grep -q "JAVA_HOME" /etc/environment; then
	log "JAVA_HOME Já Existe"
else
	# Cria JAVA_HOME em /etc/environment
	log "Adicionando JAVA_HOME em /etc/environment"
	sudo -E sh -c 'echo "JAVA_HOME=$javahome" >> /etc/environment'
	. /etc/environment
	log "JAVA_HOME = $JAVA_HOME"
fi

# Baixa a fonte do Zabbix
log "Baixando $zabbixarchive em $tmpdir"
wget -q --directory-prefix=$tmpdir "$zabbixurl" >> $logfile 2>&1
log "Extraindo $zabbixarchive para $tmpdir"
tar -xf "$tmpdir/$zabbixarchive" -C "$tmpdir" >> $logfile 2>&1
# Remove .gz
filename="${zabbixarchive%.*}"
# Remove .tar
filename="${filename%.*}"
sudo -E mv "$tmpdir/$filename" "${srcdir}" >> $logfile 2>&1

# Faz o import dos dados do Zabbix
log "Importando dados..."
cd "${srcdir}/${filename}/database/mysql" >> $logfile 2>&1
sudo -E mysql -u zabbix -p zabbix --password=$dbzabbix < schema.sql >> $logfile 2>&1
sudo -E mysql -u zabbix -p zabbix --password=$dbzabbix < images.sql >> $logfile 2>&1
sudo -E mysql -u zabbix -p zabbix --password=$dbzabbix < data.sql >> $logfile 2>&1
# Insere valores macro no monitor 'Zabbix server' (Apenas adiciona 'Template de banco MySQL para Zabbix agent')
sudo -E mysql --user=root <<_EOF_
USE zabbix;
INSERT INTO hostmacro SELECT (select max(hostmacroid)+1 from hostmacro), hostid, '{\$MYSQL.DSN}', '', 'MySQL Data Source Name', 0 FROM hosts WHERE host = 'Zabbix server'; 
INSERT INTO hostmacro SELECT (select max(hostmacroid)+1 from hostmacro), hostid, '{\$MYSQL.USER}', 'zbx_monitor', 'MySQL DB monitor password', 0 FROM hosts WHERE host = 'Zabbix server'; 
INSERT INTO hostmacro SELECT (select max(hostmacroid)+1 from hostmacro), hostid, '{\$MYSQL.PASSWORD}', 'monzabbixZaq!2wsx', 'MySQL DB monitor password', 0 FROM hosts WHERE host = 'Zabbix server';
_EOF_

# Instala o WebServer
log "Instalando o Apache e PHP..."
sudo -E apt-get -y install fping apache2 php libapache2-mod-php php-cli php-mysql php-mbstring php-gd php-xml php-bcmath php-ldap mlocate >> $logfile 2>&1
sudo -E updatedb >> $logfile 2>&1
# Define o a localização do php.ini
phpini=$(locate php.ini 2>&1 | head -n 1)
# Atualiza configuração no php.ini
sudo -E sed -i 's/max_execution_time = 30/max_execution_time = 300/g' "$phpini" >> $logfile 2>&1
sudo -E sed -i 's/memory_limit = 128M/memory_limit = 256M/g' "$phpini" >> $logfile 2>&1
sudo -E sed -i 's/post_max_size = 8M/post_max_size = 32M/g' "$phpini" >> $logfile 2>&1
sudo -E sed -i 's/max_input_time = 60/max_input_time = 300/g' "$phpini" >> $logfile 2>&1
sudo -E sed -i "s|;date.timezone =|date.timezone = $phptz|g" "$phpini" >> $logfile 2>&1
sudo -E service apache2 restart >> $logfile 2>&1

# Instala o Zabbix
log "Instalando o Zabbix Server..."
# Cria grupo e usuário
sudo -E addgroup --system --quiet zabbix >> $logfile 2>&1
sudo -E adduser --quiet --system --disabled-login --ingroup zabbix --home /var/lib/zabbix --no-create-home zabbix >> $logfile 2>&1
# Cria a home do usuário
sudo -E mkdir -m u=rwx,g=rwx,o= -p /var/lib/zabbix >> $logfile 2>&1
sudo -E chown zabbix:zabbix /var/lib/zabbix >> $logfile 2>&1
sudo -E apt-get -y install build-essential libmysqlclient-dev libssl-dev libsnmp-dev libevent-dev pkg-config golang >> $logfile 2>&1
sudo -E apt-get -y install libopenipmi-dev libcurl4-openssl-dev libxml2-dev libssh2-1-dev libpcre3-dev >> $logfile 2>&1
sudo -E apt-get -y install libldap2-dev libiksemel-dev libcurl4-openssl-dev libgnutls28-dev >> $logfile 2>&1
cd "${srcdir}/${filename}" >> $logfile 2>&1
# Escolhe as configurações
sudo -E ./configure --enable-server --enable-agent --enable-ipv6 --with-mysql --with-openssl --with-net-snmp --with-openipmi --with-libcurl --with-libxml2 --with-ssh2 --with-ldap --enable-java --prefix=/usr/local >> $logfile 2>&1
sudo -E make install >> $logfile 2>&1
# Configura o Zabbix
sudo -E chmod ug+s /usr/bin/fping
sudo -E chmod ug+s /usr/bin/fping6
sudo -E sed -i "s/# DBPassword=/DBPassword=$dbzabbix/g" "$zabbixconf" >> $logfile 2>&1
sudo -E sed -i "s|# FpingLocation=/usr/sbin/fping|FpingLocation=/usr/bin/fping|g" "$zabbixconf" >> $logfile 2>&1
sudo -E sed -i "s|# Fping6Location=/usr/sbin/fping6|Fping6Location=/usr/bin/fping6|g" "$zabbixconf" >> $logfile 2>&1
sudo -E sed -i "s/# StartPingers=1/StartPingers=10/g" "$zabbixconf" >> $logfile 2>&1

# Instala o serviço Zabbix server
log "Instalando Serviço do Zabbix..."
sudo tee -a /etc/systemd/system/zabbix-server.service > /dev/null <<EOT
[Unit]
Description=Zabbix Server
After=syslog.target network.target mysql.service
 
[Service]
Type=simple
User=zabbix
ExecStart=/usr/local/sbin/zabbix_server
ExecReload=/usr/local/sbin/zabbix_server -R config_cache_reload
RemainAfterExit=yes
PIDFile=/tmp/zabbix_server.pid
 
[Install]
WantedBy=multi-user.target
EOT
sudo -E systemctl enable zabbix-server >> $logfile 2>&1

# Instala o agente zabbix
log "Instalando o Agente do Zabbix..."
sudo tee -a /etc/systemd/system/zabbix-agent.service > /dev/null <<EOT
[Unit]
Description=Zabbix agent
After=syslog.target network.target
 
[Service]
Type=simple
User=zabbix
ExecStart=/usr/local/sbin/zabbix_agent -c /usr/local/etc/zabbix_agent.conf
RemainAfterExit=yes
PIDFile=/tmp/zabbix_agent.pid
 
[Install]
WantedBy=multi-user.target
EOT
sudo -E systemctl enable zabbix-agent >> $logfile 2>&1

# Instala o front-end do Zabbix
log "Instalando o Zabbix PHP Front End..."
cd "${srcdir}/${filename}" >> $logfile 2>&1
sudo -E mv "${srcdir}/${filename}/ui" /var/www/html/zabbix >> $logfile 2>&1
sudo -E chown -R www-data:www-data /var/www/html/zabbix >> $logfile 2>&1

# Inicia o Zabbix
log "Iniciando o Zabbix Server..."
sudo -E service zabbix-server start >> $logfile 2>&1
log "Iniciando o Agente do Zabbix..."
sudo -E service zabbix-agent start >> $logfile 2>&1
log "Removendo diretório temporário $tmpdir"
rm -rf "$tmpdir" >> $logfile 2>&1
