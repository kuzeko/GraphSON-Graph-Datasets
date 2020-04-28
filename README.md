# Reproduce datasets

## Airline

```bash

git clone https://github.com/krlawrence/graph.git practical-gremlin
chmod 777 practical-gremlin/sample-data
cd practical-gremlin/sample-data
docker run --rm -it -v ${PWD}:/datasets tinkerpop/gremlin-console
```

```gremlin

conf = new BaseConfiguration();
conf.setProperty("gremlin.tinkergraph.vertexIdManager","LONG");
conf.setProperty("gremlin.tinkergraph.edgeIdManager","LONG");
conf.setProperty("gremlin.tinkergraph.vertexPropertyIdManager","LONG");[]
graph = TinkerGraph.open(conf);
graph.io(graphml()).readGraph('/datasets/air-routes-latest.graphml');
g=graph.traversal();


g.V().property('uid',id()).iterate();[]

writer = GraphSONWriter.build().mapper(GraphSONMapper.build().version(GraphSONVersion.V3_0).create()).create();
os = new FileOutputStream("/datasets/air-routes-latest.json");
vertices = g.V();[]
while (vertices.hasNext()) {
  def v = vertices.next();
  writer.writeVertex(os, v, OUT);
  os.write("\n".getBytes());
}
os.close();


:q
```

```bash
sudo chown ${USER}:${USER} *.json
mv air-routes-latest.json ../../
```


## LDBC


```bash
mkdir ./LDBC 
cd ./LDBC

cat << EOF > ./params.ini

ldbc.snb.datagen.generator.scaleFactor:snb.interactive.10
ldbc.snb.datagen.serializer.dynamicActivitySerializer:ldbc.snb.datagen.serializer.snb.csv.dynamicserializer.activity.CsvCompositeDynamicActivitySerializer
ldbc.snb.datagen.serializer.dynamicPersonSerializer:ldbc.snb.datagen.serializer.snb.csv.dynamicserializer.person.CsvCompositeDynamicPersonSerializer
ldbc.snb.datagen.serializer.staticSerializer:ldbc.snb.datagen.serializer.snb.csv.staticserializer.CsvCompositeStaticSerializer

EOF

docker run --rm -it -v ${PWD}:/datasets tinkerpop/gremlin-console

sudo chown -R $USER:$USER  social_network substitution_parameters/



git clone https://github.com/ldbc/ldbc_snb_implementations.git

mv social_network/ substitution_parameters/ ldbc_snb_implementations/cypher/test-data/

cd ldbc_snb_implementations/cypher
chmod -R 777 .
docker run --rm -it -v ${PWD}:/cypher --entrypoint /bin/bash tinkerpop/gremlin-console

cd /cypher
sed -i s/NEO4J_VERSION=3.3.6/NEO4J_VERSION=3.2.3/ get-neo4j.sh
./get-neo4j.sh


export NEO4J_HOME=${PWD}/neo4j-server
export NEO4J_DB_DIR=$NEO4J_HOME/data/databases/graph.db
export NEO4J_DATA_DIR=${PWD}/test-data/social_network
export POSTFIX=_0_0.csv
export JAVA_OPTIONS='-Xms32G -Xmx60G -XX:+UseG1GC'

./environment-variables-neo4j.sh && ./configure-neo4j.sh && ${NEO4J_HOME}/bin/neo4j start

cd load-scripts/
./convert-csvs.sh
./delete-neo4j-database.sh
./import-to-neo4j.sh
./restart-neo4j.sh


cd ..
neo4j-server/bin/neo4j stop
chmod -R 777 neo4j-server
cd /opt/gremlin-console/

sed -i -e 's/"\${JVM_OPTS\[@\]}"/\${JVM_OPTS[@]}/' bin/gremlin.sh 

bin/gremlin.sh
```

```gremlin
:install org.apache.tinkerpop neo4j-gremlin 3.4.6
:q
```

```bash
bin/gremlin.sh
```

```gremlin
:plugin use tinkerpop.neo4j

conf = new BaseConfiguration()
conf.setProperty("gremlin.neo4j.directory","/cypher/neo4j-server/data/databases/graph.db")
conf.setProperty("gremlin.neo4j.conf.dbms.allow_format_migration","true")

graph = Neo4jGraph.open(conf)
g=graph.traversal()

size=50
c = g.V().count().next()
batch = (c/size + 1) as int

ids = g.V().id();[]
a=[];
i=0;
for( idx in ids ){
  a.add(idx);
  i++;
  if(a.size() > batch || !ids.hasNext()){
   System.out.println(i);
   a = a as Set;[];
   g.V(a).property('uid',id()).iterate();
   a=[];
  }
} 



graph.io(graphson()).writeGraph('/cypher/ldbc.scale10.json')
```


## DBPedia


```bash

cd DBpedia
git clone https://github.com/ldbc/ldbc_snb_implementations.git
# List of DBpedia files to download, the `sample` file is a smaller list for testing 
cp dbpedia_files_sample.txt  ldbc_snb_implementations/cypher/
cp dbpedia_files.txt  ldbc_snb_implementations/cypher/

cp download-dbpedia.sh  ldbc_snb_implementations/cypher/
cp import-dbpedia.sh ldbc_snb_implementations/cypher/


cd ldbc_snb_implementations/cypher
chmod -R 777 .
docker run --rm -it -v ${PWD}:/cypher --entrypoint /bin/bash tinkerpop/gremlin-console

cd /cypher
# sed -i s/NEO4J_VERSION=.+\..+\..+/NEO4J_VERSION=3.2.3/ get-neo4j.sh
sed -i -e s/NEO4J_VERSION=[0-9].[0-9].[0-9]/NEO4J_VERSION=3.2.3/ get-neo4j.sh
./get-neo4j.sh


export NEO4J_HOME=${PWD}/neo4j-server
export NEO4J_DB_DIR=$NEO4J_HOME/data/databases/graph.db
export NEO4J_DATA_DIR=${PWD}/test-data/social_network
export JAVA_OPTIONS='-Xms32G -Xmx60G -XX:+UseG1GC'

./environment-variables-neo4j.sh && ./configure-neo4j.sh && ${NEO4J_HOME}/bin/neo4j start
sleep 10
./scripts/delete-neo4j-database.sh


if [ ! -f ${NEO4J_HOME}/plugins/neosemantics-3.2.0.1-beta.jar ]
then
    echo "Downloading Neo4j RDF plugin..."
    wget -P ${NEO4J_HOME}/plugins/ https://github.com/jbarrasa/neosemantics/releases/download/3.2.0.1/neosemantics-3.2.0.1-beta.jar
fi
echo "Installing Neo4j RDF plugin..."
echo dbms.unmanaged_extension_classes=semantics.extension=/rdf >> ${NEO4J_HOME}/conf/neo4j.conf

./scripts/restart-neo4j.sh


./download-dbpedia.sh dbpedia_files.txt

#${NEO4J_HOME}/bin/neo4j start

sleep 10

./import-dbpedia.sh


${NEO4J_HOME}/bin/neo4j stop
chmod -R 777 neo4j-server
cd /opt/gremlin-console/

sed -i -e 's/"\${JVM_OPTS\[@\]}"/\${JVM_OPTS[@]}/' bin/gremlin.sh 

bin/gremlin.sh
```

```gremlin
:install org.apache.tinkerpop neo4j-gremlin 3.4.6
:q
```

```bash
bin/gremlin.sh
```

```gremlin
:plugin use tinkerpop.neo4j

conf = new BaseConfiguration();
conf.setProperty("gremlin.neo4j.directory","/cypher/neo4j-server/data/databases/graph.db");
conf.setProperty("gremlin.neo4j.conf.dbms.allow_format_migration","true");

graph = Neo4jGraph.open(conf);
g=graph.traversal();

size=50
c = g.V().count().next()
batch = (c/size + 1) as int

ids = g.V().id();[]
a=[];
i=0;
for( idx in ids ){
  a.add(idx);
  i++;
  if(a.size() > batch || !ids.hasNext()){
   System.out.println(i);
   a = a as Set;[];
   g.V(a).property('uid',id()).iterate();
   a=[];
  }
} 



size=100;
c = g.V().count().next();
batchSize = (c/size + 1) as int;
vertices = g.V();[]
counter = 0;
currentBatch = 1;
writer = GraphSONWriter.build().mapper(GraphSONMapper.build().version(GraphSONVersion.V3_0).create()).create();
os = null;
while (vertices.hasNext()) {
  def v = vertices.next()
  def newBatch = counter % batchSize == 0 ;
  if (newBatch) {
    if (null != os) os.close();
    os = new FileOutputStream("/cypher/dbpedia.${currentBatch}.json")
    currentBatch++
  }
  writer.writeVertex(os, v, OUT)
  os.write("\n".getBytes())
  counter++  
}
os.close()




:q
```

```bash
exit
cat dbpedia.[0-9]* | gzip -c > dbpedia.json.gz
rm  dbpedia.[0-9]*
```



## Uniprot


```
mkdir -p data
for fdata in `cat uniprot_files.txt`
do
wget 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/rdf/'${fdata}
xz --decompress ${fdata}
fname="${fdata%.*}"
real_name="${fname%.*}"
docker run -it --rm -v `pwd`:/rdf stain/jena riot -out N-Triples "/rdf/${fname}" > "./data/${real_name}.ttl"
rm -v $fname
done
```












