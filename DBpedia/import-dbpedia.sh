
echo "Importing data..."

export NEO4J_IMPORT="${NEO4J_HOME}/data/import"

${NEO4J_HOME}/bin/cypher-shell -u neo4j -p 'admin' "CREATE INDEX ON :Resource(uri);"
for file in ${NEO4J_IMPORT}/*.ttl; do
    # Extracting filename
    filename="$(basename "$file" .ttl).ttl"
    echo "Importing $filename from ${NEO4J_HOME}"
    ${NEO4J_HOME}/bin/cypher-shell -u neo4j -p 'admin' "CALL semantics.importRDF(\"file://${NEO4J_HOME}/import/$filename\",\"N-Triples\", { shortenUrls: true, typesToLabels: false, commitSize: 000 });"
done
