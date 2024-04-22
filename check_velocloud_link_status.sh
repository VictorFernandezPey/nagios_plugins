#!/bin/bash

##########################################
##########################################
### ___     __    __    __    ______   ###
### |  \   /  |  |  \  |  |  |  ____|  ###
### |   \_/   |  |   \ |  |  | |____   ###
### |   ___   |  |        |  |____  |  ###
### |  |   |  |  |  |\    |   ____| |  ###
### |__|   |__|  |__| \___|  |______|  ###
##########################################
##########################################

# Este script realiza una serie de operaciones relacionadas con SNMP.

# Inicializar variables con valores predeterminados
HOST=""
COMMUNITY=""
INTERFACE=""
VELO_ERROR_CODE=""

# Función de ayuda
function show_help {
    echo "Uso: $0 -h <host> -c <community> -i <interface name>"
    echo "Ejemplo: ./check_link_status_velocloud.sh -h 10.2.1.116 -c ConsolCXjd -i GE5"
    exit 1
}

# Parsear opciones
while getopts "h:c:i:" opt; do
    case $opt in
        h)
            HOST=$OPTARG
            ;;
        c)
            COMMUNITY=$OPTARG
            ;;
        i)
            INTERFACE=$OPTARG
            ;;
        *)
            show_help
            ;;
    esac
done

# Inicializar el contador
COUNT=3

# Ejecutar el comando snmpwalk y leer cada línea de salida
while IFS= read -r line; do

    # Obtener el último carácter de la línea
    last_char="${line: -1}"

    # Asignar el último carácter a una variable global con el formato OIDx
    eval "OID$COUNT=\"$last_char\""
	
    # Incrementar el contador
    ((COUNT++))
	
done < <(snmpwalk -v 2c -c $COMMUNITY $HOST SNMPv2-SMI::enterprises.45346.1.1.2.3.2.2.1.34.0.0.0)

# Verificar las variables globales creadas
#echo "Contenido de las variables globales OID:"
#for var in $(compgen -v | grep '^OID'); do
#    echo "$var=${!var}"
#done

# Determinar el valor de la variable VELO_ERROR_CODE según el valor de INTERFACE
case "$INTERFACE" in
    GE3)
        VELO_ERROR_CODE=$OID3
        ;;
    GE4)
        VELO_ERROR_CODE=$OID4
        ;;
    GE5)
        VELO_ERROR_CODE=$OID5
        ;;
    GE6)
        VELO_ERROR_CODE=$OID6
        ;;
    GE7)
        VELO_ERROR_CODE=$OID7
        ;;
    *)
        echo "Interfaz no válida: $INTERFACE"
        exit 1
        ;;
esac

# Descomentar para debug en pantalla de las variables
# echo "Valor de VELO_ERROR_CODE: $VELO_ERROR_CODE"

# Evaluar si el error code que devuelve Velo es un número o no, si no lo es es un error de timeout y lo pondremos como Warning
if [[ $VELO_ERROR_CODE =~ ^[0-9]+$ ]]; then
    # Analizar el resultado
    STATUS="UNKNOWN"
    if [[ "$VELO_ERROR_CODE" == 7 ]]; then
        STATUS="OK"
        RESULT="Link UP, Active State"
        echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
        exit 0
    elif [[ "$VELO_ERROR_CODE" == 5 ]]; then
        STATUS="OK"
        RESULT="Link UP, Standby State"
        echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
        exit 0
    elif [[ "$VELO_ERROR_CODE" == 6 ]]; then
        STATUS="DEGRADED"
        RESULT="Link UP, Degraded State"
        echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
        exit 1
    else
        STATUS="CRITICAL"
        RESULT="Link is DOWN"
        echo "$STATUS - $RESULT (VELO STATUS CODE: $VELO_ERROR_CODE)"
        exit 2
    fi
else
    STATUS="WARNING"
    RESULT="VeloCloud could not respond this pooling request"
    echo "$STATUS - $RESULT"
    exit 1
fi
