#!/bin/bash
set -e

export DATA_DIR="${PWD}/test-data/dbpedia"
export NEO4J_HOME=${PWD}/neo4j-server
export NEO4J_IMPORT="${NEO4J_HOME}/import"
mkdir -p -v "${DATA_DIR}"
mkdir -p -v "${NEO4J_IMPORT}"

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters."
    exit 1
fi

if [ -d $DATA_DIR ]
then
    echo "Downloading files..."
    rm -v ${DATA_DIR}/*.* || true
    while read -r line; do
        [[ "$line" =~ ^#.*$ ]] && continue
        wget -P ${DATA_DIR}/ $line
        bzip2 -dk ${DATA_DIR}/${line##*/}
        filename=$(basename -- "${DATA_DIR}/${line##*/}")
        filename="${filename%.*}"
        iconv -f utf-8 -t ascii//TRANSLIT -c "${DATA_DIR}/${filename}" |  grep -v 'xn--b1aew'  > ${NEO4J_IMPORT}/${filename}
        rm -v "${DATA_DIR}/${filename}"
    done < $1

    chmod -R 777 ${NEO4J_IMPORT}
else
    echo "No destination folder ${DATA_DIR}"
fi
