#!/bin/bash

reg_paginas="paginas.txt"
reg_resultados="resultados.txt"

touch "$reg_paginas"
touch "$reg_resultados"

opcion_seleccionada=""

agregar_pagina() {
    read -r -p "pone una URL: " nv_url
    
    if [ -z "$nv_url" ]; then
        echo "no diste ninguna URL."
        return 1
    fi

    if ! echo "$nv_url" | grep -q 'https\?://'; then
        nv_url="https://$nv_url"
    fi

    echo "$nv_url" >> "$reg_paginas"
    echo "URL $nv_url agregada correctamente."
}

mostrar_paginas() {
    echo "URLs:"
   
    if [ -s "$reg_paginas" ]; then
        cat -n "$reg_paginas" 
    else
        echo "el archivo $reg_paginas esta vacio, intentalo de nuevo..."
    fi
    
}

buscar_analizar() {
    read -r -p "dame una palabra para buscar " palabra_cl

    if [ -z "$palabra_cl" ]; then
        echo "tenes que ingresar una palabra, intentalo de nuevo..."
        return 1
    fi
    
    if [ ! -s "$reg_paginas" ]; then
        echo "el archivo $reg_paginas esta vacio, tenes que agregar una URL"
        return 1
    fi
    
    echo "buscando la '$palabra_cl' en las URLs de $reg_paginas"


    grep -v "^${palabra_cl} -" "$reg_resultados" > temp_resultados.txt
    mv temp_resultados.txt "$reg_resultados"


    exec 3<"$reg_paginas"
    while read -r url <&3; do
        if [ -n "$url" ]; then
            echo "revisando: $url"


            contenido=$(curl -s -L --fail --max-time 10 "$url" 2>/dev/null)
            
            if [ $? -eq 0 ] && [ -n "$contenido" ]; then
            
                cantidad=$(echo "$contenido" | grep -o -i "\b$palabra_cl\b" | wc -l)
                
                if [ "$cantidad" -gt 0 ]; then
                
                    echo "${palabra_cl} - ${url} - ${cantidad}" >> "$reg_resultados"
                    echo "se encontro $cantidad veces la palabra $palabra_cl "
                else
                    echo "no se encontro la palabra"
                fi
            else
                echo "no se pudo buscar contenido, la URL esta inaccesible o falló"
            fi
        fi
    done
    exec 3<&-
    
    echo "la busqueda termino, los resultados estan en: $reg_resultados"
}

mostrar_resultados() {
    read -r -p "pone la palabra clave para ver los resultados: " palabra_filtro

    if [ -z "$palabra_filtro" ]; then
        echo "tenes que darme una palabra clave para filtrar"
        return 1
    fi
    
    echo "--- Resultados para '$palabra_filtro' ---"

    if [ ! -s "$reg_resultados" ]; then
        echo "no hay resultados para mostrar"
        return 1
    fi

    grep "^${palabra_filtro}" "$reg_resultados" || \
    
    	echo "no existen registros para $palabra_filtro"
    
}

limpieza_y_respaldo() {
    fecha=$(date +%Y-%m-%d)

    cop_paginas="${reg_paginas%.txt}_${fecha}.txt"
  
    cop_resultados="${reg_resultados%.txt}_${fecha}.txt" 

    echo "se esta haciendo el respaldo y la limpieza"

    cp "$reg_paginas" "$cop_paginas"
    echo "la copia de $reg_paginas esta en: $cop_paginas"

    cp "$reg_resultados" "$cop_resultados"
    echo "la copia de $reg_resultados esta en: $cop_resultados"

    > "$reg_paginas"
    echo "el contenido de $reg_paginas se borro"

    > "$reg_resultados"
    echo "el contenido de $reg_resultados se borro"

    echo "Ya se terminó la limpieza y el respaldo."
}

ejecutar_todo_corrido() {

	echo "estas en modo automatico..."
   
    agregar_pagina
   
    mostrar_paginas
    
    buscar_analizar
    
    mostrar_resultados
    
    limpieza_y_respaldo
    echo "FIN DEL MODO AUTOMaTICO. Chau."
}

menu() {
    clear
    
    echo "1. Agregar pagina"
    echo "2. Mostrar paginas"
    echo "3. Buscar palabra y analizar"
    echo "4. Mostrar resultados de busqueda"
    echo "5. Limpieza y respaldo"
    echo "A. Hacer todo TODO de corrido"
    echo "0. Salir"
    
    read -r -p "Seleccione una opción: " opcion_seleccionada
}

while true; do
    
    menu
    
    case "$opcion_seleccionada" in
        1)
            agregar_pagina
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        2)
            mostrar_paginas
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        3)
            buscar_analizar
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        4)
            mostrar_resultados
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        5)
            limpieza_y_respaldo
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        [Aa])
            ejecutar_todo_corrido
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
        0)
            echo "chau"
            exit 0
            ;;
        *)
          
            echo "la opcion $opcion_seleccionada no existe"
            read -r -p "apreta la tecla [Enter] para volver"
            ;;
    esac
done
