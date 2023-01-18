
set -a
source .env
set +a

#oc login https://openshift-consola.conecel.com -u admin -p Claro.Open\$\$2020
oc login $OCP_URL -u $OCP_USER -p $OCP_PASSWORD

oc get ds --all-namespaces

oc get pods --all-namespaces -o jsonpath='{range.items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\t"}{range.status.conditions[?(.type == "Ready")]}{.status}{"\t"}{.type}{"\n"}{end}{end}' | grep False | egrep -w '(glusterfs-storage|node-exporter|sync|ovs|sdn)' > pods_nodos.tmp

echo

if [ -s pods_nodos.tmp ]; then
  echo "Existen daemonsets con problemas:"
  awk '{print $1" - " $2}' pods_nodos.tmp
  awk '{print $1}' pods_nodos.tmp | sort | uniq > pods.tmp
  while read line
  do
    pod=$line
    proyecto=$(oc get pods --all-namespaces | grep $pod | awk '{print $1}')
    echo "Reiniciando pod $pod ..."
    oc delete pod $pod -n $proyecto
    sleep 10
  done < pods.tmp
else
  echo "No existen daemonsets con prolemas"
fi

echo

rm -f pods_nodos.tmp pods.tmp nodos.tmp

