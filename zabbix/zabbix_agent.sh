#!/bin/sh

# URL do Zabbix Server
zabbixurl="https://cdn.zabbix.com/zabbix/sources/stable/5.0/zabbix-5.0.4.tar.gz"

# Váriavel para nome da URL zabbix Server
zabbixarchive=$(basename "$zabbixurl")

# Onde a fonte do Zabbix estará
srcdir="/usr/local/src"

# Configuração do agente do Zabbix
zabbixconf="/usr/local/etc/zabbix_agent.conf"

# Zabbix host
zabbixhost="DEFINIR_IP_DO_HOST"

# Diretório temporário
tmpdir="$HOME/temp"

# stdout e stderr
logfile="$PWD/install.log"
rm -f $logfile

# Log Simples
log(){
	timestamp=$(date +"%m-%d-%Y %k:%M:%S")
	echo "$timestamp $1"
	echo "$timestamp $1" >> $logfile 2>&1
}

log "Removendo diretório temporário $tmpdir"
rm -rf "$tmpdir" >> $logfile 2>&1
mkdir -p "$tmpdir" >> $logfile 2>&1

# Download do Zabbix
log "Baixando $zabbixarchive em $tmpdir"
wget -q --directory-prefix=$tmpdir "$zabbixurl" >> $logfile 2>&1
log "Extraindo $zabbixarchive para $tmpdir"
tar -xf "$tmpdir/$zabbixarchive" -C "$tmpdir" >> $logfile 2>&1
# Remove .gz
filename="${zabbixarchive%.*}"
# Remove .tar
filename="${filename%.*}"
sudo -E mv "$tmpdir/$filename" "${srcdir}" >> $logfile 2>&1

# Instala o Agente do Zabbix
log "Instalando o Agente Zabbix..."
sudo -E groupadd zabbix >> $logfile 2>&1
sudo -E useradd -g zabbix -s /bin/bash zabbix >> $logfile 2>&1
sudo -E apt-get -y install build-essential pkg-config libpcre3-dev libz-dev golang >> $logfile 2>&1
cd "${srcdir}/${filename}" >> $logfile 2>&1

sudo -E ./configure --enable-agent --prefix=/usr/local >> $logfile 2>&1
sudo -E make install >> $logfile 2>&1

sudo -E sed -i "s|Server=127.0.0.1|Server=$zabbixhost|g" "$zabbixconf" >> $logfile 2>&1
sudo -E sed -i "s|ServerActive=127.0.0.1|ServerActive=$zabbixhost|g" "$zabbixconf" >> $logfile 2>&1

# Instala o Zabbix agent como serviço
log "Instalando o Serviço do Zabbix agent..."
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

# Inicializa o agent do Zabbix
log "Iniciando o agent do zabbix..."
sudo -E service zabbix-agent start >> $logfile 2>&1
log "Removendo diretório temporário $tmpdir"
rm -rf "$tmpdir" >> $logfile 2>&1
