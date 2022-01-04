#!/bin/bash
# -*- ENCODING: UTF-8 -*-
 
ip=$1
listaPuertosAbiertos=()
listaPuertosFiltrados=()

function comprobarIp(){
	octet="(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"
	ip4Regex="^$octet\\.$octet\\.$octet\\.$octet$"
	domainRegex="((http|https)://)(www.)?[a-zA-Z0-9@:%._\\+~#?&//=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%._\\+~#?&//=]*)"
	domainRegex1="^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$" #sin http https
	while ! ([[ $ip =~ $domainRegex1 ]] || [[ $ip =~ $ip4Regex ]] || [[ $ip =~ $domainRegex ]]);
	do
		if [[ $ip == 0 ]]
		then
			read -p "Introduce una dirección ip diferente: " ip;
		else
			read -p "Formato de IP incorrecto, vuelve a decirme una ip: " ip;
		fi
	done
}

function comprobarDisponibilidadHost(){
	fping -c1 -t900 $ip 2>/dev/null 1>/dev/null #fping es igual que ping pero con tiempo en milisegundos 
	#timeout 3 bash -c "<ping -c1 $ip" 2>/dev/null 1>/dev/null
	if [[ $? == 0 ]]
	then
		echo "equipo encontrado"
		scan
	else
		echo "Equipo no encontrado"
		read -p "¿Desea continuar el análisis? s/n" -n 1 -r respuesta;
		if [[ $respuesta =~ ^[YySs]$ ]]
		then
			echo -e "\n"
			scan
		else
			echo -e "\n"
			ip=0
			comprobarIp
			comprobarDisponibilidadHost
		fi
		
	fi
}

function portOpen() {
	echo -e "	\e[0;32m[+] ${3}\e[0m --Puerto abierto"
	listaPuertosAbiertos+=($3)
	#echo "${2};${3};open;" >> "${2}.csv"
}

function portClose() {
	if [[ $1 == 124 ]] #124 termina el timer, no sabemos el estado del puerto
	then
		echo -e "	\e[0;33m[+] ${3}\e[0m -- Puerto Cerrado|filtrado"
		listaPuertosFiltrados+=($3)
		#echo "${2};${3};Filtrado;" >> "${2}.csv"
	#else
		#echo -e "	\e[0;31m[+] ${3}\e[0m -- Puerto Cerrado"
	fi
}

function scan(){
	echo -e "\e[1;33m[*]\e[0m IP válida, empezando escaneo sobre ${ip}"
	for puerto in {1..65536}
	do
		timeout 1 bash -c "</dev/tcp/${ip}/${puerto}" >/dev/null 2>&1 && portOpen $? $ip $puerto  || portClose $? $ip $puerto
	done 
}

function guardarPuertos(){
	estado=$1
	mensajeEstado=$2
	shift # quita el primero de $*, tambien shift 2
	shift
	echo -e "\e[1;33m[*]\e[0m Guardando puertos ${mensajeEstado} en el archivo:: \e[1;32m ${ip}.csv\e[0m "
	for puerto in ${@}
	do
		echo "${ip};${puerto};${estado};" >> "${ip}.csv"
	done
}

function guardarPuertosFiltrados(){
	echo -e "\e[1;33m[¿?]\e[0m ¿Desea guardar en el archivo \e[1;32m ${ip}.csv\e[0m los puertos filtrados? s/n"
	read -n 1 -r respuesta;
	echo -e "\n"
		if [[ $respuesta =~ ^[YySs]$ ]]
		then
			guardarPuertos "filtered" "filtrados" ${listaPuertosFiltrados[*]} 
		fi
}

function iniciar(){
	respuesta="s"
	while [[ $respuesta =~ ^[YySs]$ ]]
	do
		comprobarIp
		comprobarDisponibilidadHost
		guardarPuertos "open" "abiertos" ${listaPuertosAbiertos[*]} 
		guardarPuertosFiltrados
		read -p "¿Desea volver a escanear otro host?" -n 1 -r respuesta;
		echo -e "\n"
		ip=0
		listaPuertosAbiertos=()
		listaPuertosFiltrados=()
	done
	echo -e "\e[1;32m Programa finalizado!! \e[0m"
}

iniciar
